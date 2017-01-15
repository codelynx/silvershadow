//
//  PatternRenderer.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 1/15/17.
//  Copyright © 2017 Electricwoods LLC. All rights reserved.
//

import Foundation


import Foundation
import CoreGraphics
import Metal
import MetalKit
import GLKit

typealias PatternVertex = PatternRenderer.BrushFillVertex

//
//	ImageRenderer
//

class PatternRenderer: Renderer {

	typealias VertexType = BrushFillVertex

	// MARK: -

	struct BrushFillVertex {
		var x, y, z, w, u, v, s, t: Float
	}

	struct BrushFillUniforms {
		var transform: GLKMatrix4
	}


	let device: MTLDevice
	

	required init(device: MTLDevice) {
		self.device = device
	}

	func vertices(for rect: Rect) -> [BrushFillVertex] {
		let (l, r, t, b) = (rect.minX, rect.maxX, rect.maxY, rect.minY)

		//	vertex	(y)		texture	(v)
		//	1---4	(1) 		a---d 	(0)
		//	|	|			|	|
		//	2---3 	(0)		b---c 	(1)
		//

		return [
			BrushFillVertex(x: l, y: t, z: 0, w: 1, u: 0, v: 0, s: 0, t: 0),		// 1, a
			BrushFillVertex(x: l, y: b, z: 0, w: 1, u: 0, v: 1, s: 0, t: 4),		// 2, b
			BrushFillVertex(x: r, y: b, z: 0, w: 1, u: 1, v: 1, s: 4, t: 4),		// 3, c

			BrushFillVertex(x: l, y: t, z: 0, w: 1, u: 0, v: 0, s: 0, t: 0),		// 1, a
			BrushFillVertex(x: r, y: b, z: 0, w: 1, u: 1, v: 1, s: 4, t: 4),		// 3, c
			BrushFillVertex(x: r, y: t, z: 0, w: 1, u: 1, v: 0, s: 4, t: 0),		// 4, d
		]
	}

	var brushFillVertexDescriptor: MTLVertexDescriptor {
		let vertexDescriptor = MTLVertexDescriptor()
		vertexDescriptor.attributes[0].offset = 0
		vertexDescriptor.attributes[0].format = .float4
		vertexDescriptor.attributes[0].bufferIndex = 0

		vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
		vertexDescriptor.attributes[1].format = .float2
		vertexDescriptor.attributes[1].bufferIndex = 0

		vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.size * 6
		vertexDescriptor.attributes[2].format = .float2
		vertexDescriptor.attributes[2].bufferIndex = 0
		
		vertexDescriptor.layouts[0].stepFunction = .perVertex
		vertexDescriptor.layouts[0].stride = MemoryLayout<BrushFillVertex>.size
		return vertexDescriptor
	}

	lazy var brushFillRenderPipelineState: MTLRenderPipelineState = {
		let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
		renderPipelineDescriptor.vertexDescriptor = self.brushFillVertexDescriptor
		renderPipelineDescriptor.vertexFunction = self.library.makeFunction(name: "pattern_vertex")!
		renderPipelineDescriptor.fragmentFunction = self.library.makeFunction(name: "pattern_fragment")!

		renderPipelineDescriptor.colorAttachments[0].pixelFormat = defaultPixelFormat
		renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
		renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
		renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add

		renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
		renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
		renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
		renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha


		return try! self.device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
	}()

	lazy var brushMaskSamplerState: MTLSamplerState = {
		let samplerDescriptor = MTLSamplerDescriptor()
		samplerDescriptor.minFilter = .nearest
		samplerDescriptor.magFilter = .linear
		samplerDescriptor.sAddressMode = .repeat
		samplerDescriptor.tAddressMode = .repeat
		return self.device.makeSamplerState(descriptor: samplerDescriptor)
	}()

	lazy var brushPatternSamplerState: MTLSamplerState = {
		let samplerDescriptor = MTLSamplerDescriptor()
		samplerDescriptor.minFilter = .nearest
		samplerDescriptor.magFilter = .linear
		samplerDescriptor.sAddressMode = .repeat
		samplerDescriptor.tAddressMode = .repeat
		return self.device.makeSamplerState(descriptor: samplerDescriptor)
	}()

	func vertexBuffer(for vertices: [BrushFillVertex]) -> VertexBuffer<BrushFillVertex>? {
		return VertexBuffer<BrushFillVertex>(device: device, vertices: vertices)
	}

	func vertexBuffer(for rect: Rect) -> VertexBuffer<BrushFillVertex>? {
		return VertexBuffer<BrushFillVertex>(device: device, vertices: self.vertices(for: rect))
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

	func render(context: RenderContext, masking: MTLTexture, pattern: MTLTexture, vertexBuffer: VertexBuffer<BrushFillVertex>) {
		let transform = context.transform
		var uniforms = BrushFillUniforms(transform: transform)
		let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<BrushFillUniforms>.size, options: MTLResourceOptions())
		
		let encoder = context.makeRenderCommandEncoder()
		
		encoder.setRenderPipelineState(self.brushFillRenderPipelineState)

		encoder.setFrontFacing(.clockwise)
//		commandEncoder.setCullMode(.back)
		encoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, at: 0)
		encoder.setVertexBuffer(uniformsBuffer, offset: 0, at: 1)

		encoder.setFragmentTexture(masking, at: 0)
		encoder.setFragmentTexture(pattern, at: 1)
		encoder.setFragmentSamplerState(self.brushMaskSamplerState, at: 0)
		encoder.setFragmentSamplerState(self.brushPatternSamplerState, at: 1)

		encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexBuffer.count)

		encoder.endEncoding()
	}

	func render(context: RenderContext, masking: MTLTexture, pattern: MTLTexture) {
		let vertexBuffer = self.vertexBuffer(for: Rect(0, 0, 2048, 1024))!
//		let vertexBuffer = self.vertexBuffer(for: Rect(-1024, -512, 2048, 1024))!
		self.render(context: context, masking: masking, pattern: pattern, vertexBuffer: vertexBuffer)
	}

}



