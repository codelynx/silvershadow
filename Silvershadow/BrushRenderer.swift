//
//	BrushRenderer.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 1/11/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import CoreGraphics
import QuartzCore
import GLKit

typealias PenVertex = BrushRenderer.BrushShapeVertex

//
//	PenRenderer
//

class BrushRenderer: Renderer {

	typealias VertexType = BrushShapeVertex

	// TODO: needs refactoring

	struct BrushShapeVertex {
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

	//

	struct BrushFillVertex {
		var x, y, z, w, u, v, s, t: Float
	}


	let device: MTLDevice


	// MARK: -

	required init(device: MTLDevice) {
		self.device = device
	}

	var library: MTLLibrary {
		return self.device.newDefaultLibrary()!
	}

	// brush shape

	var brushShapeVertexDescriptor: MTLVertexDescriptor {
		let descriptor = MTLVertexDescriptor()
		descriptor.attributes[0].offset = 0
		descriptor.attributes[0].format = .float2
		descriptor.attributes[0].bufferIndex = 0

		descriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
		descriptor.attributes[1].format = .float2
		descriptor.attributes[1].bufferIndex = 0

		descriptor.layouts[0].stepFunction = .perVertex
		descriptor.layouts[0].stride = MemoryLayout<BrushShapeVertex>.size

		return descriptor
	}

	lazy var brushShapeRenderPipelineState: MTLRenderPipelineState = {
		let descriptor = MTLRenderPipelineDescriptor()
		descriptor.vertexDescriptor = self.brushShapeVertexDescriptor
		descriptor.vertexFunction = self.library.makeFunction(name: "brush_shape_vertex")!
		descriptor.fragmentFunction = self.library.makeFunction(name: "brush_shape_fragment")!

		descriptor.colorAttachments[0].pixelFormat = defaultPixelFormat
		descriptor.colorAttachments[0].isBlendingEnabled = true
		descriptor.colorAttachments[0].rgbBlendOperation = .add
		descriptor.colorAttachments[0].alphaBlendOperation = .add

		descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
		descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
		descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
		descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

		return try! self.device.makeRenderPipelineState(descriptor: descriptor)
	}()

	lazy var brushShapeSamplerState: MTLSamplerState = {
		let descriptor = MTLSamplerDescriptor()
		descriptor.minFilter = .nearest
		descriptor.magFilter = .linear
		descriptor.sAddressMode = .repeat
		descriptor.tAddressMode = .repeat
		return self.device.makeSamplerState(descriptor: descriptor)
	}()
	
	// brush fill
	
	var brushFillVertexDescriptor: MTLVertexDescriptor {
		let dscriptor = MTLVertexDescriptor()
		dscriptor.attributes[0].offset = 0
		dscriptor.attributes[0].format = .float4
		dscriptor.attributes[0].bufferIndex = 0

		dscriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
		dscriptor.attributes[1].format = .float2
		dscriptor.attributes[1].bufferIndex = 0

		dscriptor.attributes[2].offset = MemoryLayout<Float>.size * 6
		dscriptor.attributes[2].format = .float2
		dscriptor.attributes[2].bufferIndex = 0
		
		dscriptor.layouts[0].stepFunction = .perVertex
		dscriptor.layouts[0].stride = MemoryLayout<BrushFillVertex>.size
		return dscriptor
	}

	lazy var brushFillRenderPipelineState: MTLRenderPipelineState = {
		let descriptor = MTLRenderPipelineDescriptor()
		descriptor.vertexDescriptor = self.brushFillVertexDescriptor
		descriptor.vertexFunction = self.library.makeFunction(name: "brush_fill_vertex")!
		descriptor.fragmentFunction = self.library.makeFunction(name: "brush_fill_fragment")!

		descriptor.colorAttachments[0].pixelFormat = defaultPixelFormat
		descriptor.colorAttachments[0].isBlendingEnabled = true
		descriptor.colorAttachments[0].rgbBlendOperation = .add
		descriptor.colorAttachments[0].alphaBlendOperation = .add

		descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
		descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
		descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
		descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

		return try! self.device.makeRenderPipelineState(descriptor: descriptor)
	}()

	lazy var brushMaskSamplerState: MTLSamplerState = {
		let descriptor = MTLSamplerDescriptor()
		descriptor.minFilter = .nearest
		descriptor.magFilter = .linear
		descriptor.sAddressMode = .repeat
		descriptor.tAddressMode = .repeat
		return self.device.makeSamplerState(descriptor: descriptor)
	}()

	lazy var brushPatternSamplerState: MTLSamplerState = {
		let descriptor = MTLSamplerDescriptor()
		descriptor.minFilter = .nearest
		descriptor.magFilter = .linear
		descriptor.sAddressMode = .repeat
		descriptor.tAddressMode = .repeat
		return self.device.makeSamplerState(descriptor: descriptor)
	}()

	//

	func vertexBuffer(for vertices: [BrushShapeVertex], expanding: Int = 4096) -> VertexBuffer<BrushShapeVertex> {
		return VertexBuffer<BrushShapeVertex>(device: self.device, vertices: vertices, expanding: expanding)
	}

	func vertexes(from: Point, to: Point, width: Float) -> [BrushShapeVertex] {
		let vector = (to - from)
		let numberOfPoints = Int(ceil(vector.length / 2))
		let step = vector / Float(numberOfPoints)
		return (0 ..< numberOfPoints).map {
			BrushShapeVertex(from + step * Float($0), width)
		}
	}

	class func vertexes(of cgPath: CGPath, width: CGFloat) -> [BrushShapeVertex] {
		var vertexes = [BrushShapeVertex]()
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
					vertexes.append(BrushShapeVertex(Point(q), Float(width)))
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
					vertexes.append(BrushShapeVertex(Point(r), Float(width)))
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
					vertexes.append(BrushShapeVertex(Point(s), Float(width)))
				}

			case .closeSubpath:
				guard let p0 = lastPoint, let p1 = startPoint else { continue }

				let n = Int((p1 - p0).length)
				for i in 0 ..< n {
					let t = CGFloat(i) / CGFloat(n)
					let q = p0 + (p1 - p0) * t
					vertexes.append(BrushShapeVertex(Point(q), Float(width)))
				}
			}
		}
		
		return vertexes
	}

	func brushFillVertices(for rect: Rect) -> [BrushFillVertex] {
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

	//

	func render(context: RenderContext, masking: MTLTexture, brushShape: MTLTexture, brushFill: MTLTexture, vertexBuffer: VertexBuffer<BrushShapeVertex>) {
		let transform = context.transform
		var uniforms = Uniforms(transform: transform, zoomScale: Float(context.zoomScale))
		let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.size, options: MTLResourceOptions())

		//
		//	Brush Shape
		//

		let subcommandBuffer = context.makeCommandBuffer()
		let subrenderPassDescriptor = MTLRenderPassDescriptor()
		subrenderPassDescriptor.colorAttachments[0].texture = masking
		subrenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0) // <-- !!!
		subrenderPassDescriptor.colorAttachments[0].storeAction = .store

		// clear the subtexture
		subrenderPassDescriptor.colorAttachments[0].loadAction = .clear
		let clearEncoder = subcommandBuffer.makeRenderCommandEncoder(descriptor: subrenderPassDescriptor)
		clearEncoder.endEncoding()
 
		let subencoder = subcommandBuffer.makeRenderCommandEncoder(descriptor: subrenderPassDescriptor)
		subencoder.setRenderPipelineState(self.brushShapeRenderPipelineState)

		subencoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, at: 0)
		subencoder.setVertexBuffer(uniformsBuffer, offset: 0, at: 1)

		subencoder.setFragmentTexture(brushShape, at: 0)
		subencoder.setFragmentSamplerState(self.brushShapeSamplerState, at: 0)

		subencoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexBuffer.count)
		subencoder.endEncoding()

		subcommandBuffer.commit()
		subcommandBuffer.waitUntilCompleted()


//		let image: NSImage! = masking.image!

		//
		// Brush Fill
		//

	if true {
		let commandBuffer = context.commandBuffer
		let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: context.renderPassDescriptor)
		
		encoder.setRenderPipelineState(self.brushFillRenderPipelineState)

//		let (l, r, t, b) = (rect.minX, rect.maxX, rect.maxY, rect.minY)
		let (l, r, t, b) = (Float(-1), Float(1), Float(1), Float(-1))

		let (u, v) = (Float(2048) / 100.0, Float(1024) / 100.0)
//		let (u, v) = (Float(1), Float(1))

//		let brushFillVetrexes = self.brushFillVertices(for: Rect(0, 0, 2024, 1024))
		let brushFillVetrexes: [BrushFillVertex] = [

			//	vertex	(y)		texture	(v)
			//	1---4	(1) 		a---d 	(0)
			//	|	|			|	|
			//	2---3 	(0)		b---c 	(1)

			BrushFillVertex(x: l, y: t, z: 0, w: 1, u: 0, v: 0, s: 0, t: 0),		// 1, a
			BrushFillVertex(x: l, y: b, z: 0, w: 1, u: 0, v: 1, s: 0, t: v),		// 2, b
			BrushFillVertex(x: r, y: b, z: 0, w: 1, u: 1, v: 1, s: u, t: v),		// 3, c

			BrushFillVertex(x: l, y: t, z: 0, w: 1, u: 0, v: 0, s: 0, t: 0),		// 1, a
			BrushFillVertex(x: r, y: b, z: 0, w: 1, u: 1, v: 1, s: u, t: v),		// 3, c
			BrushFillVertex(x: r, y: t, z: 0, w: 1, u: 1, v: 0, s: u, t: 0),		// 4, d
		]



		let brushFillVertexBuffer = VertexBuffer<BrushFillVertex>(device: device, vertices: brushFillVetrexes)

		encoder.setFrontFacing(.clockwise)
//		commandEncoder.setCullMode(.back)
		encoder.setVertexBuffer(brushFillVertexBuffer.buffer, offset: 0, at: 0)
		encoder.setVertexBuffer(uniformsBuffer, offset: 0, at: 1)

		encoder.setFragmentTexture(masking, at: 0)
		encoder.setFragmentTexture(brushFill, at: 1)
		encoder.setFragmentSamplerState(self.brushMaskSamplerState, at: 0)
		encoder.setFragmentSamplerState(self.brushPatternSamplerState, at: 1)

		encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: brushFillVertexBuffer.count)

		encoder.endEncoding()
	}
		// debug
	if false {
		let fillTransform = GLKMatrix4Identity
		let renderContext = RenderContext(renderPassDescriptor: context.renderPassDescriptor,
						commandBuffer: context.commandBuffer, contentSize: context.contentSize, transform: fillTransform, zoomScale: 1)
		renderContext.render(texture: masking, in: Rect(-1, -1, 2, 2))
	}
//		let imageRenderer: ImageRenderer = self.device.renderer()
//		imageRenderer.render(context: context, texture: masking, rect: Rect(0, 0, 2048, 1024))


//		let renderContext = RenderContext(renderPassDescriptor: context.renderPassDescriptor,
//						commandBuffer: context.commandBuffer, contentSize: context.contentSize, transform: GLKMatrix4Identity, zoomScale: 1)
//		renderContext.render(texture: context.maskingTexture!, in: Rect(-1, -1, 2, 2))

//		let patternRenderer: PatternRenderer = self.device.renderer()
//		patternRenderer.render(context: context, masking: masking, pattern: brushFill)


//		print(image)
	}

	func render(context: RenderContext, masking: MTLTexture, brushShape: MTLTexture, brushFill: MTLTexture, cgPath: CGPath, width: CGFloat) {
		let vertexes = BrushRenderer.vertexes(of: cgPath, width: width)
		let vertexBuffer = self.vertexBuffer(for: vertexes)
		self.render(context: context, masking: masking, brushShape: brushShape, brushFill: brushFill, vertexBuffer: vertexBuffer)
	}
}


extension RenderContext {

//	func render(vertexes: [PenVertex], texture: MTLTexture) {
//		let renderer: PenRenderer = self.device.renderer()
//		let vertexBuffer = renderer.vertexBuffer(for: vertexes)
//		renderer.render(context: self, texture: texture, vertexBuffer: vertexBuffer)
//	}

}

