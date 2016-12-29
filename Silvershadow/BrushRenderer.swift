//
//	ImageRenderer.swift
//	Metal2DScroll
//
//	Created by Kaz Yoshikawa on 12/22/15.
//
//

import Foundation
import CoreGraphics
import Metal
import MetalKit
import GLKit

typealias BrushVertex = BrushRenderer.Vertex

//
//	ImageRenderer
//

class BrushRenderer: Renderer {

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
		vertexDescriptor.attributes[0].format = .float4
		vertexDescriptor.attributes[0].offset = 0
		vertexDescriptor.attributes[0].bufferIndex = 0
		vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint
		vertexDescriptor.layouts[0].stepRate = 1
		vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 4

//		vertexDescriptor.attributes[1].offset = 0
//		vertexDescriptor.attributes[1].format = .float2
//		vertexDescriptor.attributes[1].bufferIndex = 0
		
		return vertexDescriptor
	}

	lazy var renderPipelineState: MTLRenderPipelineState = {
		let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
		renderPipelineDescriptor.vertexDescriptor = self.vertexDescriptor
		renderPipelineDescriptor.sampleCount = 1 // TBD
		renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
		renderPipelineDescriptor.fragmentFunction = self.library.makeFunction(name: "brush_tessellation_fragment")!

		renderPipelineDescriptor.isTessellationFactorScaleEnabled = false
		renderPipelineDescriptor.tessellationFactorFormat = .half
		renderPipelineDescriptor.tessellationControlPointIndexType = .none
		renderPipelineDescriptor.tessellationFactorStepFunction = .constant
		renderPipelineDescriptor.tessellationOutputWindingOrder = .clockwise
		renderPipelineDescriptor.tessellationPartitionMode = MTLTessellationPartitionMode(rawValue: 3)!
		renderPipelineDescriptor.maxTessellationFactor = 64 // max 64?


		renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
		renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
		renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
		renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add

		renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
		renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
		renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
		renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

		renderPipelineDescriptor.vertexFunction = self.library.makeFunction(name: "brush_tessellation_vertex_quad")!

		do { return try self.device.makeRenderPipelineState(descriptor: renderPipelineDescriptor) }
		catch { fatalError("\(error)") }
	}()

	lazy var computePipelineState: MTLComputePipelineState = {
		let kernelFunction = self.library.makeFunction(name: "brush_tessellation_kernel_quad")!
		do { return try self.device.makeComputePipelineState(function: kernelFunction) }
		catch { fatalError("\(error)") }
	}()

	lazy var colorSamplerState: MTLSamplerState = {
		let samplerDescriptor = MTLSamplerDescriptor()
		samplerDescriptor.minFilter = .nearest
		samplerDescriptor.magFilter = .linear
		samplerDescriptor.sAddressMode = .repeat
		samplerDescriptor.tAddressMode = .repeat
		return self.device.makeSamplerState(descriptor: samplerDescriptor)
	}()

	lazy var tessellationFactorsBuffer: MTLBuffer = {
		let buffer = self.device.makeBuffer(length: 256, options: [.storageModePrivate])
		buffer.label = "Tessellation Factors"
		return buffer
	}()

	lazy var controlPointsBufferQuad: MTLBuffer = {
		let controlPointPositionsQuad: [Float] = [
			-0.8,  0.8, 0.0, 1.0,   // upper-left
			 0.8,  0.8, 0.0, 1.0,   // upper-right
			 0.8, -0.8, 0.0, 1.0,   // lower-right
			-0.8, -0.8, 0.0, 1.0,   // lower-left
		];
		let buffer = self.device.makeBuffer(bytes: controlPointPositionsQuad, length: MemoryLayout<Float>.size * 16, options: [.storageModeManaged])
		return buffer
	}()

	// MARK: -
	
	func computeTessellationFactorsWithCommandBuffer(context: RenderContext) {
		let commandEncoder = context.commandBuffer.makeComputeCommandEncoder()
		commandEncoder.label = "Compute Command Encoder"
		
		commandEncoder.pushDebugGroup("Compute Tessellation Factors")
		commandEncoder.setComputePipelineState(self.computePipelineState)
		
		let size = MTLSize(width: 1, height: 1, depth: 1)
		commandEncoder.dispatchThreadgroups(size, threadsPerThreadgroup: size)

		commandEncoder.popDebugGroup()
		commandEncoder.endEncoding()
	}
	
	
	// MARK: -

	func render(context: RenderContext) {

		// compute command encoder

		let computeCommandEncoder = context.commandBuffer.makeComputeCommandEncoder()
		computeCommandEncoder.label = "Compute Command Encoder"
		
		computeCommandEncoder.pushDebugGroup("Compute Tessellation Factors")
		computeCommandEncoder.setComputePipelineState(self.computePipelineState)

		var edgeFactor: Float = 16.0
		var insideFactor: Float = 16.0
		computeCommandEncoder.setBytes(&edgeFactor, length: MemoryLayout<Float>.size, at: 0)
		computeCommandEncoder.setBytes(&insideFactor, length: MemoryLayout<Float>.size, at: 1)

		computeCommandEncoder.setBuffer(self.tessellationFactorsBuffer, offset: 0, at: 2)
		let size = MTLSize(width: 1, height: 1, depth: 1)
		computeCommandEncoder.dispatchThreadgroups(size, threadsPerThreadgroup: size)

		computeCommandEncoder.popDebugGroup()
		computeCommandEncoder.endEncoding()


		// render command encoder
		
		let encoder = context.makeRenderCommandEncoder()
		encoder.pushDebugGroup("Tessellate and Render")

		encoder.setRenderPipelineState(self.renderPipelineState)
		encoder.setVertexBuffer(self.controlPointsBufferQuad, offset: 0, at: 0)

		encoder.setTessellationFactorBuffer(self.tessellationFactorsBuffer, offset: 0, instanceStride: 0)
		let patchControlPoints = 4
		encoder.drawPatches(numberOfPatchControlPoints: patchControlPoints, patchStart: 0, patchCount: 1, patchIndexBuffer: nil,
					patchIndexBufferOffset: 0, instanceCount: 1, baseInstance: 0)

		encoder.popDebugGroup()
		encoder.endEncoding()
	}

}


extension RenderContext {

}

