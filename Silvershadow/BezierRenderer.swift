//
//  BezierRenderer.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 1/7/17.
//  Copyright © 2017 Electricwoods LLC. All rights reserved.
//

import Foundation
import CoreGraphics
import QuartzCore
import GLKit
import simd



class BezierRenderer: Renderer {

	typealias VertexType = Vertex

	// TODO: needs refactoring

	enum ElementType: UInt8 {
		case lineTo = 2
		case quadCurveTo = 3
		case curveTo = 4
	};

	struct PathElement {
		var type: UInt8					// 0
		var unused1: UInt8				// 1
		var unused2: UInt8				// 2
		var unused3: UInt8				// 3

		var numberOfVertexes: UInt16		// 4
		var vertexIndex: UInt16			// 6

		var width1: UInt16				// 8
		var width2: UInt16				// 10
		var unused4: UInt16				// 12 .. somehow needed
		var unused5: UInt16				// 14 .. somehow needed

		var p0: Point					// 16
		var p1: Point					// 24
		var p2: Point					// 32
		var p3: Point					// 40
										// 48

		init(type: ElementType, numberOfVertexes: Int, vertexIndex: Int, w1: Int, w2: Int, p0: Point, p1: Point, p2: Point, p3: Point) {
			self.type = type.rawValue
			self.unused1 = 0
			self.unused2 = 0
			self.unused3 = 0
			self.numberOfVertexes = UInt16(numberOfVertexes)
			self.vertexIndex = UInt16(vertexIndex)
			self.width1 = UInt16(w1)
			self.width2 = UInt16(w2)
			self.unused4 = 0
			self.unused5 = 0
			self.p0 = p0
			self.p1 = p1
			self.p2 = p2
			self.p3 = p3
		}
	}


	struct Vertex {
		var x: Float16
		var y: Float16
		var width: Float16
		var unused: Float16 = Float16(0.0)

		init(x: Float, y: Float, width: Float) {
			self.x = Float16(x)
			self.y = Float16(y)
			self.width = Float16(width)
		}
		
		init(point: Point, width: Float) {
			self.x = Float16(point.x)
			self.y = Float16(point.y)
			self.width = Float16(width)
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
	
	lazy var computePipelineState: MTLComputePipelineState = {
		let function = self.library.makeFunction(name: "bezier_kernel")!
		return try! self.device.makeComputePipelineState(function: function)
	}()

	var vertexDescriptor: MTLVertexDescriptor {
		let vertexDescriptor = MTLVertexDescriptor()
		vertexDescriptor.attributes[0].offset = 0
		vertexDescriptor.attributes[0].format = .half2
		vertexDescriptor.attributes[0].bufferIndex = 0

		vertexDescriptor.attributes[1].offset = MemoryLayout<Float16>.size * 2
		vertexDescriptor.attributes[1].format = .half2
		vertexDescriptor.attributes[1].bufferIndex = 0

		vertexDescriptor.layouts[0].stepFunction = .perVertex
		vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride

		return vertexDescriptor
	}

	lazy var renderPipelineState: MTLRenderPipelineState = {
		let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
		renderPipelineDescriptor.vertexDescriptor = self.vertexDescriptor
		renderPipelineDescriptor.vertexFunction = self.library.makeFunction(name: "bezier_vertex")!
		renderPipelineDescriptor.fragmentFunction = self.library.makeFunction(name: "bezier_fragment")!

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


	func render(context: RenderContext, texture: MTLTexture, cgPaths: [CGPath]) {

		var elements = [PathElement]()
		var vertexCount: Int = 0
		let nan2 = Point(Float.nan, Float.nan)
		let (w1, w2) = (32, 32)

		// extract PathElement

		for cgPath in cgPaths {
			var origin: Point?
			var lastPoint: Point?

			let pathElements = cgPath.pathElements
			for pathElement in pathElements {
				switch pathElement {
				case .moveTo(let p1):
					origin = Point(p1)
					lastPoint = Point(p1)
				case .lineTo(let p1):
					let (p0, p1) = (lastPoint!, Point(p1))
					let count = Int((p0 - p1).length)
					let element = PathElement(type: .lineTo, numberOfVertexes: count, vertexIndex: vertexCount,
								w1: w1, w2: w2, p0: p0, p1: p1, p2: nan2, p3: nan2)
					elements.append(element)
					vertexCount += count
					lastPoint = p1
				case .quadCurveTo(let p1, let p2):
					let (p0, p1, p2) = (lastPoint!, Point(p1), Point(p2))
					let count = Int(((p0 - p1).length + (p2 - p1).length) * sqrt(2)) // todo
					let element = PathElement(type: .quadCurveTo, numberOfVertexes: count, vertexIndex: vertexCount,
								w1: w1, w2: w2, p0: p0, p1: p1, p2: p2, p3: nan2)
					elements.append(element)
					vertexCount += count
					lastPoint = p2
				case .curveTo(let p1, let p2, let p3):
					let (p0, p1, p2, p3) = (lastPoint!, Point(p1), Point(p2), Point(p3))
					let count = Int((p0 - p1).length + (p2 - p1).length + (p3 - p2).length + (p3 - p0).length) // todo
					let element = PathElement(type: .curveTo, numberOfVertexes: count, vertexIndex: vertexCount,
								w1: w1, w2: w2, p0: p0, p1: p1, p2: p2, p3: p3)
					elements.append(element)
					vertexCount += count
					lastPoint = p3
				case .closeSubpath:
					lastPoint = nil
					origin = nil
					break
				}
			}
		}
		
		// build contiguous vertexes using computing shader from PathElement
		
		let elementsBuffer = VertexBuffer<PathElement>(device: self.device, vertices: elements)
		let vertexes = Array<Vertex>(repeatElement(Vertex(point: Point(0, 0), width: 0), count: Int(vertexCount)))
		let vertexBuffer = VertexBuffer<Vertex>(device: self.device, vertices: vertexes)

		do {
			let commandBuffer = context.makeCommandBuffer()
			let encoder = commandBuffer.makeComputeCommandEncoder()
			encoder.setComputePipelineState(self.computePipelineState)
			encoder.setBuffer(elementsBuffer.buffer, offset: 0, at: 0)
			encoder.setBuffer(vertexBuffer.buffer, offset: 0, at: 1)
			let threadgroupsPerGrid = MTLSizeMake(1, 1, 1)
			let threadsPerThreadgroup = MTLSizeMake(elements.count, 1, 1)
			encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
			encoder.endEncoding()
			commandBuffer.commit()
			commandBuffer.waitUntilCompleted()
		}

		// vertex buffer should be filled with vertexes then draw it

		do {
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
		
	}

}


