//
//	ImageRenderer.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/22/15.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import CoreGraphics
import MetalKit
import GLKit
import simd


//
//	ImageRenderer
//

class PatternRenderer: Renderer {
	
	typealias VertexType = Vertex
	
	// MARK: -
	
	struct Vertex {
		var x, y, z, w, u, v: Float
		var padding: SIMD2<Float>
		init(x: Float, y: Float, z: Float, w: Float, u: Float, v: Float) {
			self.x = x
			self.y = y
			self.z = z
			self.w = w
			self.u = u
			self.v = v
			self.padding = .init()
		}
	}
	
	struct Uniforms {
		var transform: GLKMatrix4
		var contentSize: SIMD2<Float>
		var patternSize: SIMD2<Float>
	}
	
	let device: MTLDevice
	
	
	required init(device: MTLDevice) {
		self.device = device
	}
	
	func vertices(for rect: Rect) -> [Vertex] {
		let (l, r, t, b) = (rect.minX, rect.maxX, rect.maxY, rect.minY)
		
		//	vertex	(y)		texture	(v)
		//	1---4	(1) 		a---d 	(0)
		//	|	|			|	|
		//	2---3 	(0)		b---c 	(1)
		//
		
		return [
			Vertex(x: l, y: t, z: 0, w: 1, u: 0, v: 0),		// 1, a
			Vertex(x: l, y: b, z: 0, w: 1, u: 0, v: 1),		// 2, b
			Vertex(x: r, y: b, z: 0, w: 1, u: 1, v: 1),		// 3, c
			
			Vertex(x: l, y: t, z: 0, w: 1, u: 0, v: 0),		// 1, a
			Vertex(x: r, y: b, z: 0, w: 1, u: 1, v: 1),		// 3, c
			Vertex(x: r, y: t, z: 0, w: 1, u: 1, v: 0),		// 4, d
		]
	}
	
	var vertexDescriptor: MTLVertexDescriptor {
		let vertexDescriptor = MTLVertexDescriptor()
		vertexDescriptor.attributes[0].offset = 0
		vertexDescriptor.attributes[0].format = .float4
		vertexDescriptor.attributes[0].bufferIndex = 0
		
		vertexDescriptor.attributes[1].offset = 0
		vertexDescriptor.attributes[1].format = .float2
		vertexDescriptor.attributes[1].bufferIndex = 0
		
		vertexDescriptor.layouts[0].stepFunction = .perVertex
		vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.size
		return vertexDescriptor
	}
	
	lazy var renderPipelineState: MTLRenderPipelineState = {
		let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
		renderPipelineDescriptor.vertexDescriptor = self.vertexDescriptor
		renderPipelineDescriptor.vertexFunction = self.library.makeFunction(name: "pattern_vertex")!
		renderPipelineDescriptor.fragmentFunction = self.library.makeFunction(name: "pattern_fragment")!
		
		renderPipelineDescriptor.colorAttachments[0].pixelFormat = .`default`
		renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
		renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
		renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
		
		renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
		renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
		renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
		renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
		
		return try! self.device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
	}()
	
	lazy var shadingSamplerState: MTLSamplerState = {
		return self.device.makeSamplerState(descriptor: .`default`)!
	}()
	
	lazy var patternSamplerState: MTLSamplerState = {
		return self.device.makeSamplerState(descriptor: .`default`)!
	}()
	
	func vertexBuffer(for vertices: [Vertex]) -> VertexBuffer<Vertex>? {
		return VertexBuffer(device: device, vertices: vertices)
	}
	
	func vertexBuffer(for rect: Rect) -> VertexBuffer<Vertex>? {
		return VertexBuffer(device: device, vertices: vertices(for: rect))
	}
	
	func texture(of image: XImage) -> MTLTexture? {
		guard let cgImage: CGImage = image.cgImage else { return nil }
		var options: [String : NSObject] = [convertFromMTKTextureLoaderOption(MTKTextureLoader.Option.SRGB): false as NSNumber]
		if #available(iOS 10.0, *) {
			options[convertFromMTKTextureLoaderOption(MTKTextureLoader.Option.origin)] = true as NSNumber
		}
		return try? device.textureLoader.newTexture(cgImage: cgImage, options: convertToOptionalMTKTextureLoaderOptionDictionary(options))
	}
	
	// MARK: -
	
	
	// prepare triple reusable buffers for avoid race condition
	
	lazy var uniformTripleBuffer: [MTLBuffer] = {
		return [
			self.device.makeBuffer(length: MemoryLayout<Uniforms>.size, options: [.storageModeShared])!,
			self.device.makeBuffer(length: MemoryLayout<Uniforms>.size, options: [.storageModeShared])!,
			self.device.makeBuffer(length: MemoryLayout<Uniforms>.size, options: [.storageModeShared])!
		]
	}()
	
	let rectangularVertexCount = 6
	
	lazy var rectVertexTripleBuffer: [MTLBuffer] = {
		let len = MemoryLayout<Vertex>.size * self.rectangularVertexCount
		return [
			self.device.makeBuffer(length: len, options: [.storageModeShared])!,
			self.device.makeBuffer(length: len, options: [.storageModeShared])!,
			self.device.makeBuffer(length: len, options: [.storageModeShared])!
		]
	}()
	
	var tripleBufferIndex = 0
	
	func renderPattern(context: RenderContext, in rect: Rect) {
		defer { tripleBufferIndex = (tripleBufferIndex + 1) % uniformTripleBuffer.count }
		
		let uniformsBuffer = uniformTripleBuffer[tripleBufferIndex]
		let uniformsBufferPtr = UnsafeMutablePointer<Uniforms>(OpaquePointer(uniformsBuffer.contents()))
		uniformsBufferPtr.pointee.transform = context.transform
		
		uniformsBufferPtr.pointee.contentSize = SIMD2<Float>(Float(context.deviceSize.width), Float(context.deviceSize.height))
		uniformsBufferPtr.pointee.patternSize = SIMD2<Float>(Float(context.brushPattern.width), Float(context.brushPattern.height))
		
		let vertexes = self.vertices(for: rect)
		assert(vertexes.count == rectangularVertexCount)
		let vertexBuffer = rectVertexTripleBuffer[tripleBufferIndex]
		let vertexArrayPtr = UnsafeMutablePointer<Vertex>(OpaquePointer(vertexBuffer.contents()))
		let vertexArray = UnsafeMutableBufferPointer<Vertex>(start: vertexArrayPtr, count: vertexes.count)
		(0 ..< vertexes.count).forEach { vertexArray[$0] = vertexes[$0] }
		
		let commandBuffer = context.makeCommandBuffer()
		let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: context.renderPassDescriptor)!
		encoder.pushDebugGroup("pattern filling")
		
		encoder.setRenderPipelineState(self.renderPipelineState)
		
		encoder.setFrontFacing(.clockwise)
		//		commandEncoder.setCullMode(.back)
		encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
		encoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
		
		encoder.setFragmentTexture(context.shadingTexture, index: 0)
		encoder.setFragmentTexture(context.brushPattern, index: 1)
		encoder.setFragmentSamplerState(self.shadingSamplerState, index: 0)
		encoder.setFragmentSamplerState(self.patternSamplerState, index: 1)
		encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
		
		encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexes.count)
		
		encoder.popDebugGroup()
		encoder.endEncoding()
		commandBuffer.commit()
	}
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromMTKTextureLoaderOption(_ input: MTKTextureLoader.Option) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalMTKTextureLoaderOptionDictionary(_ input: [String: Any]?) -> [MTKTextureLoader.Option: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (MTKTextureLoader.Option(rawValue: key), value)})
}
