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


extension MTLDevice {

	var textureLoader: MTKTextureLoader {
		return MTKTextureLoader(device: self)
	}

	func texture(of image: CGImage, options: [String : NSObject]? = nil) -> MTLTexture? {
		var _options: [String : NSObject] = [MTKTextureLoaderOptionSRGB: false as NSNumber]
		if #available(iOS 10.0, *) {
			_options[MTKTextureLoaderOptionOrigin] = true as NSNumber
		}
		if let options = options {
			for (key, value) in options {
				_options[key] = value
			}
		}
		return try? self.textureLoader.newTexture(with: image, options: _options)
	}

	func texture(of image: XImage, options: [String : NSObject]? = nil) -> MTLTexture? {
		guard let cgImage: CGImage = image.cgImage else { return nil }
		return self.texture(of: cgImage, options: options)
	}

}


//
//	ImageNode
//

class ImageRenderable: Renderable {

	typealias RendererType = ImageRenderer

	let device: MTLDevice
	var transform = GLKMatrix4Identity

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
		self.renderer.renderImage(context: context, texture: texture, vertexBuffer: vertexBuffer)
	}
	
}

