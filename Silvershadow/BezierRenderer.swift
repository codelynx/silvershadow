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
import MetalKit
import GLKit
import simd


extension CGPoint {
    static let nan = CGPoint(CGFloat.nan, CGFloat.nan)
}

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

		renderPipelineDescriptor.colorAttachments[0].pixelFormat = .`default`
		renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
		renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
		renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add

		// I don't believe this but this is what it is...
		renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
		renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
		renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
		renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

		return try! self.device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
	}()

	lazy var shapeSamplerState: MTLSamplerState = {
		return self.device.makeSamplerState(descriptor: .`default`)
	}()

	lazy var patternSamplerState: MTLSamplerState = {
		return self.device.makeSamplerState(descriptor: .`default`)
	}()

	private typealias LineSegment = (type: ElementType, length: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint)

	private func lineSegments(cgPaths: [CGPath]) -> [LineSegment] {

        return cgPaths.flatMap { (cgPath) -> [LineSegment] in

            var origin: CGPoint?
            var lastPoint: CGPoint?

            return cgPath.pathElements.flatMap {
                switch $0 {
                case let .moveTo(p1):
                    origin = p1
                    lastPoint = p1
                case let .lineTo(p1):
                    guard let p0 = lastPoint else { return nil }
                    let length = (p0 - p1).length
                    lastPoint = p1
                    return (.lineTo, length, p0, p1, .nan, .nan)
                case let .quadCurveTo(p1, p2):
                    guard let p0 = lastPoint else { return nil }
                    let length = CGPath.quadraticCurveLength(p0, p1, p2)
                    lastPoint = p2
                    return (.quadCurveTo, length, p0, p1, p2, .nan)
                case let .curveTo(p1, p2, p3):
                    guard let p0 = lastPoint else { return nil }
                    let length = CGPath.approximateCubicCurveLength(p0, p1, p2, p3)
                    lastPoint = p3
                    return (.curveTo, length, p0, p1, p2, p3)
                case .closeSubpath:
                    guard let p0 = lastPoint, let p1 = origin else { return nil }
                    let length = (p0 - p1).length
                    lastPoint = nil
                    origin = nil
                    return (.lineTo, length, p0, p1, .nan, .nan)
                }
                return nil
            }
        }
	}
	
	// MARK: -
	
	#if os(iOS)
	lazy var heap: XHeap = {
		return self.device.makeHeap(size: 1024 * 1024 * 64) // ??
	}()
	#endif

	#if os(macOS)
	var heap: XHeap { return self.device }
	#endif


	func makeElementBuffer(elements: [BezierPathElement]) -> MetalBuffer<BezierPathElement> {
		return MetalBuffer(heap: heap, vertices: elements)
	}

	func makeVertexBuffer(vertices: [Vertex]?, capacity: Int) -> MetalBuffer<Vertex> {
		return MetalBuffer(heap: heap, vertices: vertices, capacity: capacity)
	}

	let vertexCapacity = 40_000
	let elementsCapacity = 4_000
	
	// MARK: -

	func render(context: RenderContext, cgPaths: [CGPath]) {
		guard cgPaths.count > 0 else { return }

		var elementsArray = [[BezierPathElement]]()
		let (w1, w2) = (8, 8)

		let segments = lineSegments(cgPaths: cgPaths)
		let totalLength = segments.reduce(CGFloat(0)) { $0 + $1.length }
		print("totalLength=\(totalLength)")

		var elements = [BezierPathElement]()
		var vertexCount: Int = 0
		var elementCount: Int = 0

		// due to limited memory resource, all vertexes may not be able to render at a time, but on the other hand, it should not render segment
		// by segment because of performance.  Following code sprits line segments by vertex buffer's capacity.

		for segment in segments {
			let count = Int(ceil(segment.length))
			if vertexCount + count > vertexCapacity || elementCount + 1 > elementsCapacity {
				elementsArray.append(elements)
				elements = [BezierPathElement]()
				vertexCount = 0
				elementCount = 0
			}
			let element = BezierPathElement(type: segment.type, numberOfVertexes: count, vertexIndex: vertexCount, w1: w1, w2: w2,
					p0: Point(segment.p0), p1: Point(segment.p1), p2: Point(segment.p2), p3: Point(segment.p3))
			elements.append(element)
			vertexCount += count
			elementCount += 1
		}
		if elements.count > 0 {
			elementsArray.append(elements)
		}


		// now, elements are sprited 


		var uniforms = Uniforms(transform: context.transform,
		                        zoomScale: Float(context.zoomScale))
		let uniformsBuffer = device.makeBuffer(bytes: &uniforms,
		                                       length: MemoryLayout<Uniforms>.size, options: [])


		// Now shading brush stroke on shadingTexture

		let shadingRenderPassDescriptor = MTLRenderPassDescriptor()
		shadingRenderPassDescriptor.colorAttachments[0].texture = context.shadingTexture
		shadingRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
		shadingRenderPassDescriptor.colorAttachments[0].loadAction = .clear
		shadingRenderPassDescriptor.colorAttachments[0].storeAction = .store

		print("elementsArray=\(elementsArray.count)")

		for elements in elementsArray {

			let vertexCount = elements.map { $0.numberOfVertexes }.reduce (0, +)
			guard vertexCount > 0 else { continue }

			let commandBuffer = context.makeCommandBuffer()
			let elementBuffer = makeElementBuffer(elements: elements)
			let vertexBuffer = makeVertexBuffer(vertices: [], capacity: Int(vertexCount))

			// build contiguous vertexes using computing shader from PathElement
			
			do {
				let encoder = commandBuffer.makeComputeCommandEncoder()
				encoder.pushDebugGroup("bezier - kernel")
				encoder.setComputePipelineState(computePipelineState)

				elementBuffer.set(elements)
				encoder.setBuffer(elementBuffer.buffer, offset: 0, at: 0)
				encoder.setBuffer(vertexBuffer.buffer, offset: 0, at: 1)
				let threadgroupsPerGrid = MTLSizeMake(elements.count, 1, 1)
				let threadsPerThreadgroup = MTLSizeMake(1, 1, 1)
				encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

				encoder.popDebugGroup()
				encoder.endEncoding()
			}

			// vertex buffer should be filled with vertexes then draw it

			do {
				let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadingRenderPassDescriptor)
				encoder.pushDebugGroup("bezier - brush shaping")
				encoder.setRenderPipelineState(renderPipelineState)

				encoder.setFrontFacing(.clockwise)

				encoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, at: 0)
				encoder.setVertexBuffer(uniformsBuffer, offset: 0, at: 1)

				encoder.setFragmentTexture(context.brushShape, at: 0)
				encoder.setFragmentSamplerState(shapeSamplerState, at: 0)

				encoder.setFragmentTexture(context.brushPattern, at: 1)
				encoder.setFragmentSamplerState(patternSamplerState, at: 1)

				encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Int(vertexCount))
				encoder.popDebugGroup()
				encoder.endEncoding()
			}

			commandBuffer.commit()

			shadingRenderPassDescriptor.colorAttachments[0].loadAction = .load
		}

		/*
		let p1 = float4x4(context.transform.invert) * float4(-1, -1, 0, 1)
		let p2 = float4x4(context.transform.invert) * float4(+1, +1, 0, 1)
		let (l, r, t, b) = (p1.x, p2.x, min(p1.y, p2.y), max(p1.y, p2.y))
		*/

		// offscreen buffer does not require transform ??
		context.pushContext()
		context.transform = GLKMatrix4Identity
		let renderer = context.device.renderer() as PatternRenderer
		renderer.renderPattern(context: context, in: Rect(-1, -1, 2, 2)) // ??
		context.popContext()
	}

}


