//
//	MTLDevice+Z.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 1/10/17.
//	Copyright © 2017 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit

extension MTLDevice {
	
	var textureLoader: MTKTextureLoader {
		return MTKTextureLoader(device: self)
	}
	
	func texture(of image: CGImage) -> MTLTexture? {
		
		let textureUsage : MTLTextureUsage = [.pixelFormatView, .shaderRead]
		var options: [String : NSObject] = [
			convertFromMTKTextureLoaderOption(MTKTextureLoader.Option.SRGB): false as NSNumber,
			convertFromMTKTextureLoaderOption(MTKTextureLoader.Option.textureUsage): textureUsage.rawValue as NSNumber
		]
		if #available(iOS 10.0, *) {
			options[convertFromMTKTextureLoaderOption(MTKTextureLoader.Option.origin)] = true as NSNumber
		}
		
		guard let texture = try? self.textureLoader.newTexture(cgImage: image, options: convertToOptionalMTKTextureLoaderOptionDictionary(options)) else { return nil }
		
		if texture.pixelFormat == .bgra8Unorm { return texture }
		else { return texture.makeTextureView(pixelFormat: .bgra8Unorm) }
	}
	
	func texture(of image: XImage) -> MTLTexture? {
		return image.cgImage.flatMap { self.texture(of: $0) }
	}
	
	func texture(named name: String) -> MTLTexture? {
		var options = [String: NSObject]()
		options[convertFromMTKTextureLoaderOption(MTKTextureLoader.Option.SRGB)] = false as NSNumber
		if #available(iOS 10.0, *) {
			options[convertFromMTKTextureLoaderOption(MTKTextureLoader.Option.origin)] = convertFromMTKTextureLoaderOrigin(MTKTextureLoader.Origin.topLeft) as NSObject
		}
		do { return try self.textureLoader.newTexture(name: name, scaleFactor: 1.0, bundle: nil, options: convertToOptionalMTKTextureLoaderOptionDictionary(options)) }
		catch { fatalError("\(error)") }
	}
	
	#if os(iOS)
	func makeHeap(size: Int) -> MTLHeap {
		let descriptor = MTLHeapDescriptor()
		descriptor.storageMode = .shared
		descriptor.size = size
		return self.makeHeap(descriptor: descriptor)!
	}
	#endif
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromMTKTextureLoaderOption(_ input: MTKTextureLoader.Option) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalMTKTextureLoaderOptionDictionary(_ input: [String: Any]?) -> [MTKTextureLoader.Option: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (MTKTextureLoader.Option(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromMTKTextureLoaderOrigin(_ input: MTKTextureLoader.Origin) -> String {
	return input.rawValue
}
