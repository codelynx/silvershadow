//
//  MTLDevice+Z.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 1/10/17.
//  Copyright © 2017 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit



extension MTLDevice {

	var textureLoader: MTKTextureLoader {
		return MTKTextureLoader(device: self)
	}

	func texture(of image: CGImage) -> MTLTexture? {

		var options: [String : NSObject] = [MTKTextureLoaderOptionSRGB: false as NSNumber]
		if #available(iOS 10.0, *) {
			options[MTKTextureLoaderOptionOrigin] = true as NSNumber
		}
		let texture = try? self.textureLoader.newTexture(with: image, options: options)
		assert(texture!.pixelFormat == .bgra8Unorm)
		return texture
	}

	func texture(of image: XImage) -> MTLTexture? {
		guard let cgImage: CGImage = image.cgImage else { return nil }
		return self.texture(of: cgImage)
	}

	func texture(named name: String) -> MTLTexture? {
		var options = [String: NSObject]()
		options[MTKTextureLoaderOptionSRGB] = false as NSNumber
		if #available(iOS 10.0, *) {
			options[MTKTextureLoaderOptionOrigin] = MTKTextureLoaderOriginTopLeft as NSObject
		}
		do { return try self.textureLoader.newTexture(withName: name, scaleFactor: 1.0, bundle: nil, options: options) }
		catch { fatalError("\(error)") }
	}
}
