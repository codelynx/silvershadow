//
//	PointsRenderer.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 1/11/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import CoreGraphics
import QuartzCore
import GLKit

typealias PointVertex = PointsRenderer.Vertex

//
//	PointsRenderer
//

class PointsRenderer: Renderer {

	typealias VertexType = Vertex

	// TODO: needs refactoring

	struct Vertex {
		var x: Float
		var y: Float
		var width: Float
		var unused: Float = 0

		init(x: Float, y: Float, width: Float) {
			self.x = x
			self.y = y
			self.width = width
		}
		
		init(point: Point, width: Float) {
			self.x = point.x
			self.y = point.y
			self.width = width
		}

	}

	struct Uniforms {
		var transform: GLKMatrix4
		var zoomScale: Float
		var unused2: Float = 0
		var unused3: Float = 0
		var unused4: Float = 0
		
		init(transform: GLKMatrix4, zoomScale: Float) {
			self.transform = transform
			self.zoomScale = zoomScale
		}
	}

	let device: MTLDevice


	// MARK: -

	required init(device: MTLDevice) {
		self.device = device
	}

	var library: MTLLibrary {
		return self.device.newDefaultLibrary()!
	}

	var vertexDescriptor: MTLVertexDescriptor {
		let vertexDescriptor = MTLVertexDescriptor()
		vertexDescriptor.attributes[0].offset = 0
		vertexDescriptor.attributes[0].format = .float2
		vertexDescriptor.attributes[0].bufferIndex = 0

		vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
		vertexDescriptor.attributes[1].format = .float
		vertexDescriptor.attributes[1].bufferIndex = 0

		vertexDescriptor.layouts[0].stepFunction = .perVertex
		vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.size

		return vertexDescriptor
	}

	lazy var renderPipelineState: MTLRenderPipelineState = {
		let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
		renderPipelineDescriptor.vertexDescriptor = self.vertexDescriptor
		renderPipelineDescriptor.vertexFunction = self.library.makeFunction(name: "points_vertex")!
		renderPipelineDescriptor.fragmentFunction = self.library.makeFunction(name: "points_fragment")!

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

	lazy var colorSamplerState: MTLSamplerState = {
		let samplerDescriptor = MTLSamplerDescriptor()
		samplerDescriptor.minFilter = .nearest
		samplerDescriptor.magFilter = .linear
		samplerDescriptor.sAddressMode = .repeat
		samplerDescriptor.tAddressMode = .repeat
		return self.device.makeSamplerState(descriptor: samplerDescriptor)
	}()
	
	func vertexBuffer(for vertices: [Vertex], capacity: Int = 4096) -> VertexBuffer<Vertex> {
		return VertexBuffer<Vertex>(device: self.device, vertices: vertices, expand: capacity)
	}

	func render(context: RenderContext, texture: MTLTexture, vertexBuffer: VertexBuffer<Vertex>) {
		let transform = context.transform
		var uniforms = Uniforms(transform: transform, zoomScale: Float(context.zoomScale))
		let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.size, options: MTLResourceOptions())

		let encoder = context.makeRenderCommandEncoder()
		encoder.setRenderPipelineState(self.renderPipelineState)

		encoder.setFrontFacing(.clockwise)
		encoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, at: 0)
		encoder.setVertexBuffer(uniformsBuffer, offset: 0, at: 1)

		encoder.setFragmentTexture(texture, at: 0)
		encoder.setFragmentSamplerState(self.colorSamplerState, at: 0)

		encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexBuffer.count)
		encoder.endEncoding()
	}

	func render(context: RenderContext, texture: MTLTexture, vertexes: [Vertex]) {
		let vertexBuffer = self.vertexBuffer(for: vertexes)
		self.render(context: context, texture: texture, vertexBuffer: vertexBuffer)
	}

	func render(context: RenderContext, texture: MTLTexture, points: [Point], width: Float) {
		var vertexes = [Vertex]()
		points.pair { (p1, p2) in
			vertexes += self.vertexes(from: p1, to: p2, width: width)
		}
		self.render(context: context, texture: texture, vertexes: vertexes)
	}

	func vertexes(from: Point, to: Point, width: Float) -> [Vertex] {
		let vector = (to - from)
		let numberOfPoints = Int(ceil(vector.length / 2))
		let step = vector / Float(numberOfPoints)
		return (0 ..< numberOfPoints).map {
			Vertex(point: from + step * Float($0), width: width)
		}
	}

}


extension RenderContext {

	func render(vertexes: [PointVertex], texture: MTLTexture) {
		let renderer: PointsRenderer = self.device.renderer()
		let vertexBuffer = renderer.vertexBuffer(for: vertexes)
		renderer.render(context: self, texture: texture, vertexBuffer: vertexBuffer)
	}

	func render(points: [Point], texture: MTLTexture, width: Float) {
		let renderer: PointsRenderer = self.device.renderer()
		renderer.render(context: self, texture: texture, points: points, width: width)
	}

}

