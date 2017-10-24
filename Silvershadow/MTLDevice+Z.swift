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

		let textureUsage : MTLTextureUsage = [.pixelFormatView, .shaderRead]
		var options: [MTKTextureLoader.Option : Any] = [
			MTKTextureLoader.Option.SRGB: false,
			MTKTextureLoader.Option.textureUsage: textureUsage.rawValue as NSNumber
		]
		if #available(iOS 10.0, *) {
			options[MTKTextureLoader.Option.origin] = true as NSNumber
		}

		guard let texture = try? self.textureLoader.newTexture(cgImage: image, options: options) else { return nil }

		if texture.pixelFormat == .bgra8Unorm { return texture }
		else { return texture.makeTextureView(pixelFormat: .bgra8Unorm) }
	}

	func texture(of image: XImage) -> MTLTexture? {
        return image.cgImage.flatMap { self.texture(of: $0) }
	}

	func texture(named name: String) -> MTLTexture? {
		var options = [MTKTextureLoader.Option: Any]()
		options[MTKTextureLoader.Option.SRGB] = false
		if #available(iOS 10.0, *) {
			options[MTKTextureLoader.Option.origin] = MTKTextureLoader.Origin.topLeft as NSObject
		}
		do { return try self.textureLoader.newTexture(name: name, scaleFactor: 1.0, bundle: nil, options: options) }
		catch { fatalError("\(error)") }
	}

	#if os(iOS)
	func makeHeap(size: Int) -> MTLHeap {
		let descriptor = MTLHeapDescriptor()
		descriptor.storageMode = .shared
		descriptor.size = size
		return self.makeHeap(descriptor: descriptor)
	}
	#endif
}
