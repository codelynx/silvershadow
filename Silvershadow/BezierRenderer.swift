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

	struct BezierPathElement {
		var type: UInt8					// 0
		var unused1: UInt8				// 1
		var unused2: UInt8				// 2
		var unused3: UInt8				// 3

		var numberOfVertexes: UInt16	// 4
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

		// I don't believe this but this is what it is...
		#if os(iOS)
		renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
		renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
		#elseif os(macOS)
		renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
		renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
		#endif
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


	private typealias LineSegment = (type: ElementType, length: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint)

	private func lineSegments(cgPaths: [CGPath]) -> [LineSegment] {
		let nan2 = CGPoint(CGFloat.nan, CGFloat.nan)
	
		return cgPaths.map { (cgPath) -> [LineSegment] in

			var origin: CGPoint?
			var lastPoint: CGPoint?

			return cgPath.pathElements.flatMap { (pathElement) -> LineSegment? in
				switch pathElement {
				case .moveTo(let p1):
					origin = p1
					lastPoint = p1
				case .lineTo(let p1):
					guard let p0 = lastPoint else { return nil }
					let length = (p0 - p1).length
					lastPoint = p1
					return (.lineTo, length, p0, p1, nan2, nan2)
				case .quadCurveTo(let p1, let p2):
					guard let p0 = lastPoint else { return nil }
					let length = ((p0 - p1).length + (p2 - p1).length) * sqrt(2) // todo
					lastPoint = p2
					return (.quadCurveTo, length, p0, p1, p2, nan2)
				case .curveTo(let p1, let p2, let p3):
					guard let p0 = lastPoint else { return nil }
					let length = (p0 - p1).length + (p2 - p1).length + (p3 - p2).length + (p3 - p0).length // todo
					lastPoint = p3
					return (.curveTo, length, p0, p1, p2, p3)
				case .closeSubpath:
					guard let p0 = lastPoint, let p1 = origin else { return nil }
					let length = (p0 - p1).length
					lastPoint = nil
					origin = nil
					return (.lineTo, length, p0, p1, nan2, nan2)
				}
				return nil
			}

		}
		.flatMap { $0 }
	}


	func render(context: RenderContext, texture: MTLTexture, cgPaths: [CGPath]) {
		guard cgPaths.count > 0 else { return }

		let vertexCapacity = 10_000
		var elementsArray = [[BezierPathElement]]()
		let (w1, w2) = (32, 32)

		let segments = self.lineSegments(cgPaths: cgPaths)
		let totalLength = segments.reduce(CGFloat(0)) { (total, value) in return total + value.length }
		print("totalLength=\(totalLength)")

		var elements = [BezierPathElement]()
		var vertexCount: Int = 0

		// due to limited memory resource, all vertexes may not be able to render at a time, but on the other hand, it should not render segment
		// by segment because of performance.  Following code sprits line segments by vertex buffer's capacity.

		for segment in segments {
			let count = Int(segment.length / 2)
			if vertexCount + count > vertexCapacity {
				elementsArray.append(elements)
				elements = [BezierPathElement]()
				vertexCount = 0
			}
			let element = BezierPathElement(type: segment.type, numberOfVertexes: count, vertexIndex: vertexCount, w1: w1, w2: w2,
					p0: Point(segment.p0), p1: Point(segment.p1), p2: Point(segment.p2), p3: Point(segment.p3))
			elements.append(element)
			vertexCount += count
		}
		if elements.count > 0 {
			elementsArray.append(elements)
		}


		// now, elements are sprited 

		for (index, elements) in elementsArray.enumerated() {
			print("pass = \(index)")

			let commandBuffer = context.makeCommandBuffer()

			// build contiguous vertexes using computing shader from PathElement
			
			let elementsBuffer = VertexBuffer<BezierPathElement>(device: self.device, vertices: elements)
			let vertexes = Array<Vertex>(repeatElement(Vertex(point: Point(0, 0), width: 0), count: Int(vertexCount)))
			let vertexBuffer = VertexBuffer<Vertex>(device: self.device, vertices: vertexes)

			do {
				let encoder = commandBuffer.makeComputeCommandEncoder()
				encoder.setComputePipelineState(self.computePipelineState)
				encoder.setBuffer(elementsBuffer.buffer, offset: 0, at: 0)
				encoder.setBuffer(vertexBuffer.buffer, offset: 0, at: 1)
				let threadgroupsPerGrid = MTLSizeMake(elements.count, 1, 1)
				let threadsPerThreadgroup = MTLSizeMake(1, 1, 1)
				encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
				encoder.endEncoding()
			}

			// vertex buffer should be filled with vertexes then draw it

			do {
				let transform = context.transform
				var uniforms = Uniforms(transform: transform, zoomScale: Float(context.zoomScale))
				let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.size, options: MTLResourceOptions())

				let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: context.renderPassDescriptor)
				encoder.setRenderPipelineState(self.renderPipelineState)

				encoder.setFrontFacing(.clockwise)
				encoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, at: 0)
				encoder.setVertexBuffer(uniformsBuffer, offset: 0, at: 1)

				encoder.setFragmentTexture(texture, at: 0)
				encoder.setFragmentSamplerState(self.colorSamplerState, at: 0)

				encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexBuffer.count)
				encoder.endEncoding()
			}

			commandBuffer.commit()
			commandBuffer.waitUntilCompleted()
		}

	}

}


