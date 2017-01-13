//
//	PenRenderer.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 1/11/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import CoreGraphics
import QuartzCore
import GLKit

typealias PenVertex = PenRenderer.Vertex

//
//	PenRenderer
//

class PenRenderer: Renderer {

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
		
		init(_ point: Point, _ width: Float) {
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
		vertexDescriptor.attributes[1].format = .float2
		vertexDescriptor.attributes[1].bufferIndex = 0

		vertexDescriptor.layouts[0].stepFunction = .perVertex
		vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.size

		return vertexDescriptor
	}

	lazy var renderPipelineState: MTLRenderPipelineState = {
		let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
		renderPipelineDescriptor.vertexDescriptor = self.vertexDescriptor
		renderPipelineDescriptor.vertexFunction = self.library.makeFunction(name: "pen_vertex")!
		renderPipelineDescriptor.fragmentFunction = self.library.makeFunction(name: "pen_fragment")!

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
	
	func vertexBuffer(for vertices: [Vertex], expanding: Int = 4096) -> VertexBuffer<Vertex> {
		return VertexBuffer<Vertex>(device: self.device, vertices: vertices, expanding: expanding)
	}

	func render(context: RenderContext, texture: MTLTexture, vertexBuffer: VertexBuffer<Vertex>) {
		let transform = context.transform
		var uniforms = Uniforms(transform: transform, zoomScale: Float(context.zoomScale))
		let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.size, options: MTLResourceOptions())

		let subcommandBuffer = context.makeCommandBuffer()
		let subrenderPassDescriptor = MTLRenderPassDescriptor()
		subrenderPassDescriptor.colorAttachments[0].texture = context.maskingTexture!
		subrenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
		subrenderPassDescriptor.colorAttachments[0].storeAction = .store

		// clear the subtexture
		subrenderPassDescriptor.colorAttachments[0].loadAction = .clear
		let clearEncoder = subcommandBuffer.makeRenderCommandEncoder(descriptor: subrenderPassDescriptor)
		clearEncoder.endEncoding()

//		let subtransform = GLKMatrix4(CGRect(origin: CGPoint.zero, size: context.contentSize).transform(to: CGRect(-1, -1, 2, 2)))
//		subrenderPassDescriptor.colorAttachments[0].loadAction = .load
//		let subrenderContext = RenderContext(renderPassDescriptor: subrenderPassDescriptor,
//					commandBuffer: subcommandBuffer, transform: context.transform, zoomScale: 1)
//		canvasLayer.render(context: subrenderContext)

		let subencoder = subcommandBuffer.makeRenderCommandEncoder(descriptor: subrenderPassDescriptor)
		subencoder.setRenderPipelineState(self.renderPipelineState)

		subencoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, at: 0)
		subencoder.setVertexBuffer(uniformsBuffer, offset: 0, at: 1)

		subencoder.setFragmentTexture(texture, at: 0)
		subencoder.setFragmentSamplerState(self.colorSamplerState, at: 0)

		subencoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexBuffer.count)
		subencoder.endEncoding()

		subcommandBuffer.commit()
		subcommandBuffer.waitUntilCompleted()

		let image: NSImage! = context.maskingTexture!.image!

		let renderContext = RenderContext(renderPassDescriptor: context.renderPassDescriptor,
						commandBuffer: context.commandBuffer, contentSize: context.contentSize, transform: GLKMatrix4Identity, zoomScale: 1)
		renderContext.render(texture: context.maskingTexture!, in: Rect(-1, -1, 2, 2))



		print(image)
	}

	func render(context: RenderContext, texture: MTLTexture, vertexes: [Vertex]) {
		let vertexBuffer = self.vertexBuffer(for: vertexes)
		self.render(context: context, texture: texture, vertexBuffer: vertexBuffer)
	}

	func vertexes(from: Point, to: Point, width: Float) -> [Vertex] {
		let vector = (to - from)
		let numberOfPoints = Int(ceil(vector.length / 2))
		let step = vector / Float(numberOfPoints)
		return (0 ..< numberOfPoints).map {
			Vertex(from + step * Float($0), width)
		}
	}

	class func vertexes(of cgPath: CGPath, width: CGFloat) -> [Vertex] {
		var vertexes = [Vertex]()
		var startPoint: CGPoint?
		var lastPoint: CGPoint?

		for pathElement in cgPath.pathElements {
			switch pathElement {
			case .moveToPoint(let p1):
				startPoint = p1
				lastPoint = p1

			case .addLineToPoint(let p1):
				guard let p0 = lastPoint else { continue }
				lastPoint = p1

				let n = Int((p1 - p0).length)
				for i in 0 ..< n {
					let t = CGFloat(i) / CGFloat(n)
					let q = p0 + (p1 - p0) * t
					vertexes.append(Vertex(Point(q), Float(width)))
				}

			case .addQuadCurveToPoint(let p1, let p2):
				guard let p0 = lastPoint else { continue }
				lastPoint = p2

				let n = Int((p1 - p0).length + (p2 - p1).length)
				for i in 0 ..< n {
					let t = CGFloat(i) / CGFloat(n)
					let q1 = p0 + (p1 - p0) * t
					let q2 = p1 + (p2 - p1) * t
					let r = q1 + (q2 - q1) * t
					vertexes.append(Vertex(Point(r), Float(width)))
				}

			case .addCurveToPoint(let p1, let p2, let p3):
				guard let p0 = lastPoint else { continue }
				lastPoint = p3

				// http://math.stackexchange.com/questions/12186/arc-length-of-bézier-curves
				// http://gamedev.stackexchange.com/questions/6009/bezier-curve-arc-length
				// http://stackoverflow.com/questions/29438398/cheap-way-of-calculating-cubic-bezier-length

				let chord = (p3 - p0).length
				let est_length = (p1 - p0).length + (p2 - p1).length + (p3 - p2).length
				let n = Int((est_length + chord) * 0.5)
				for i in 0 ..< n {
					let t = CGFloat(i) / CGFloat(n)
					let q1 = p0 + (p1 - p0) * t
					let q2 = p1 + (p2 - p1) * t
					let q3 = p2 + (p3 - p2) * t
					let r1 = q1 + (q2 - q1) * t
					let r2 = q2 + (q3 - q2) * t
					let s = r1 + (r2 - r1) * t
					vertexes.append(Vertex(Point(s), Float(width)))
				}

			case .closeSubpath:
				guard let p0 = lastPoint, let p1 = startPoint else { continue }

				let n = Int((p1 - p0).length)
				for i in 0 ..< n {
					let t = CGFloat(i) / CGFloat(n)
					let q = p0 + (p1 - p0) * t
					vertexes.append(Vertex(Point(q), Float(width)))
				}
			}
		}
		
		return vertexes
	}

	func render(context: RenderContext, texture: MTLTexture, cgPath: CGPath, width: CGFloat) {
		let vertexes = PenRenderer.vertexes(of: cgPath, width: width)
		self.render(context: context, texture: texture, vertexes: vertexes)
	}
}


extension RenderContext {

	func render(vertexes: [PenVertex], texture: MTLTexture) {
		let renderer: PenRenderer = self.device.renderer()
		let vertexBuffer = renderer.vertexBuffer(for: vertexes)
		renderer.render(context: self, texture: texture, vertexBuffer: vertexBuffer)
	}

}

