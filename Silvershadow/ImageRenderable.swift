//
//	ImageRenderable.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 1/11/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


//
//	ImageNode
//

class ImageRenderable: Renderable {

	typealias RendererType = ImageRenderer

	let device: MTLDevice
    var transform : GLKMatrix4 = .identity

	var image: XImage
	var frame: Rect
	let texture: MTLTexture

	lazy var vertexBuffer: VertexBuffer<ImageVertex> = {
		let vertexes = self.renderer.vertices(for: self.frame)
		return self.renderer.vertexBuffer(for: vertexes)!
	}()

	init?(device: MTLDevice, image: XImage, frame: Rect) {
		guard let texture = device.texture(of: image) else { return nil }
		self.device = device
		self.image = image
		self.frame = frame
		self.texture = texture
	}

	func render(context: RenderContext) {
		self.renderer.renderTexture(context: context, texture: texture, in: frame)
	}
	
}

