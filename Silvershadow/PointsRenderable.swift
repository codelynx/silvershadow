//
//	PointsRenderable.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 1/11/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


//
//	PointsRenderable
//

class PointsRenderable: Renderable {

	typealias RendererType = PointsRenderer

	let device: MTLDevice
	var texture: MTLTexture
	var vertices: [PointVertex]

	lazy var vertexBuffer: VertexBuffer<PointVertex> = {
		return self.renderer.vertexBuffer(for: self.vertices, capacity: 4096)
	}()

	init?(device: MTLDevice, texture: MTLTexture, vertices: [PointVertex]) {
		self.device = device
		self.texture = texture
		self.vertices = vertices
	}

	init?(device: MTLDevice, texture: MTLTexture, cgPath: CGPath, width: CGFloat) {
		self.device = device
		self.texture = texture
		self.vertices = PointsRenderer.vertexes(of: cgPath, width: width)
	}

	
	func render(context: RenderContext) {
		renderer.render(context: context, texture: texture, vertexBuffer: vertexBuffer)
	}
	
	func append(_ vertices: [PointVertex]) {
		self.vertices += vertices
		if self.vertices.count < vertexBuffer.count {
			self.vertexBuffer.append(vertices)
		}
		else {
			let vertexBuffer = renderer.vertexBuffer(for: self.vertices, capacity: 4096)
			self.vertexBuffer = vertexBuffer
		}
	}
}
