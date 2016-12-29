//
//	ColorRenderable.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/13/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import CoreGraphics
import MetalKit
import GLKit


class ColorRectRenderable: Renderable {

	typealias RendererType = ColorRenderer

	let device: MTLDevice
	lazy var vertexBuffer: VertexBuffer<ColorVertex> = {
		let renderer = self.renderer
		let vertices = renderer.vertices(for: self.frame, color: self.color)
		return renderer.vertexBuffer(for: vertices)!
	}()
	var frame: Rect
	var color: XColor
	
	init?(device: MTLDevice, frame: Rect, color: XColor) {
		self.device = device
		self.frame = frame
		self.color = color
		let vertices = renderer.vertices(for: frame, color: color)
		guard let vertexBuffer = renderer.vertexBuffer(for: vertices) else { return nil }
		self.vertexBuffer = vertexBuffer
	}

	func render(context: RenderContext) {
		self.renderer.render(context: context, vertexBuffer: vertexBuffer)
	}

}


class ColorTriangleRenderable: Renderable {

	typealias RendererType = ColorRenderer

	let device: MTLDevice
	var point1: ColorVertex
	var point2: ColorVertex
	var point3: ColorVertex

	lazy var vertexBuffer: VertexBuffer<ColorVertex> = {
		let vertices: [ColorVertex] = [ self.point1, self.point2, self.point3 ]
		return self.renderer.vertexBuffer(for: vertices)!
	}()
	
	init?(device: MTLDevice, point1: ColorVertex, point2: ColorVertex, point3: ColorVertex) {
		self.device = device
		self.point1 = point1
		self.point2 = point2
		self.point3 = point3
	}

	func render(context: RenderContext) {
		self.renderer.render(context: context, vertexBuffer: vertexBuffer)
	}

}
