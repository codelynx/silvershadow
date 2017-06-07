//
//	Renderer.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/12/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//


import MetalKit
import GLKit

extension MTLPixelFormat {
    static let `default` : MTLPixelFormat = .bgra8Unorm
}

protocol Renderer: class {
	var device: MTLDevice { get }
	init(device: MTLDevice)
}


extension Renderer {
	var library: MTLLibrary {
		return self.device.newDefaultLibrary()!
	}
}


class DictLike<Key : Hashable, Value> {
    private var content : [Key: Value] = [:]
    subscript(key: Key) -> Value? {
        get { return content[key] }
        set { content[key] = newValue }
    }
}

final class RendererRegistry : DictLike<String, Renderer> { }

func aligned(length: Int, alignment: Int) -> Int {
	return length + ((alignment - (length % alignment)) % alignment)
}

final class RenderMap : NSMapTable<MTLDevice, RendererRegistry> {
    static let shared = RenderMap.weakToStrongObjects()
}

extension MTLDevice {

	func renderer<T: Renderer>() -> T {
		let key = NSStringFromClass(T.self)
		let registry = RenderMap.shared.object(forKey: self) ?? RendererRegistry()
		let renderer = registry[key] ?? T(device: self)
		registry[key] = renderer
		RenderMap.shared.setObject(registry, forKey: self)
		return renderer as! T
	}

}

