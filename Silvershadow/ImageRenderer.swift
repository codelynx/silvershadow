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

typealias ImageVertex = ImageRenderer.Vertex

//
//	ImageRenderer
//

class ImageRenderer: Renderer {

	typealias VertexType = Vertex

	// MARK: -

	struct Vertex {
		var x, y, z, w, u, v: Float
	}

	struct Uniforms {
		var transform: GLKMatrix4
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
		renderPipelineDescriptor.vertexFunction = self.library.makeFunction(name: "image_vertex")!
		renderPipelineDescriptor.fragmentFunction = self.library.makeFunction(name: "image_fragment")!

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

	lazy var colorSamplerState: MTLSamplerState = {
		return self.device.makeSamplerState(descriptor: .`default`)
	}()

	func vertexBuffer(for vertices: [Vertex]) -> VertexBuffer<Vertex>? {
		return VertexBuffer(device: device, vertices: vertices)
	}

	func vertexBuffer(for rect: Rect) -> VertexBuffer<Vertex>? {
		return VertexBuffer(device: device, vertices: vertices(for: rect))
	}
	
	func texture(of image: XImage) -> MTLTexture? {
		guard let cgImage: CGImage = image.cgImage else { return nil }
		var options: [String : NSObject] = [MTKTextureLoaderOptionSRGB: false as NSNumber]
		if #available(iOS 10.0, *) {
			options[MTKTextureLoaderOptionOrigin] = true as NSNumber
		}
		return try? device.textureLoader.newTexture(with: cgImage, options: options)
	}
	
	// MARK: -

	// prepare triple reusable buffers for avoid race condition
	lazy var uniformTripleBuffer: [MTLBuffer] = {
		return [
			self.device.makeBuffer(length: MemoryLayout<Uniforms>.size, options: [.storageModeShared]),
			self.device.makeBuffer(length: MemoryLayout<Uniforms>.size, options: [.storageModeShared]),
			self.device.makeBuffer(length: MemoryLayout<Uniforms>.size, options: [.storageModeShared])
		]
	}()

	let rectangularVertexCount = 6

	lazy var rectangularVertexTripleBuffer: [VertexBuffer<Vertex>] = {
		let count = self.rectangularVertexCount
		return [
			VertexBuffer<Vertex>(device: self.device, vertices: [], capacity: count),
			VertexBuffer<Vertex>(device: self.device, vertices: [], capacity: count),
			VertexBuffer<Vertex>(device: self.device, vertices: [], capacity: count)
		]
	}()
	
	var tripleBufferIndex = 0

	func renderTexture(context: RenderContext, texture: MTLTexture, in rect: Rect) {
		defer { tripleBufferIndex = (tripleBufferIndex + 1) % uniformTripleBuffer.count }

		let uniformsBuffer = uniformTripleBuffer[tripleBufferIndex]
		let uniformsBufferPtr = UnsafeMutablePointer<Uniforms>(OpaquePointer(uniformsBuffer.contents()))
		uniformsBufferPtr.pointee.transform = context.transform

		let vertices = self.vertices(for: rect)
		let vertexBuffer = rectangularVertexTripleBuffer[tripleBufferIndex]
		vertexBuffer.set(vertices)

		let commandBuffer = context.makeCommandBuffer()
		let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: context.renderPassDescriptor)
		encoder.pushDebugGroup("image")
		encoder.setRenderPipelineState(self.renderPipelineState)

		encoder.setFrontFacing(.clockwise)
//		commandEncoder.setCullMode(.back)
		encoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, at: 0)
		encoder.setVertexBuffer(uniformsBuffer, offset: 0, at: 1)

		encoder.setFragmentTexture(texture, at: 0)
		encoder.setFragmentSamplerState(self.colorSamplerState, at: 0)

		encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexBuffer.count)
		encoder.popDebugGroup()
		encoder.endEncoding()

		commandBuffer.commit()
	}
}


extension RenderContext {

	func render(texture: MTLTexture?, in rect: Rect) {
		guard let texture = texture else { return }
		let renderer = self.device.renderer() as ImageRenderer
		renderer.renderTexture(context: self, texture: texture, in: rect)
	}

	func render(image: XImage?, in rect: Rect) {
		guard let image = image else { return }
		let device = self.device
		guard let texture = device.texture(of: image) else { return }
		self.render(texture: texture, in: rect)
	}

}

