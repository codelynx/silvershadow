//
//	Renderer.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/12/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif


import MetalKit
import GLKit


var defaultPixelFormat: MTLPixelFormat = .bgra8Unorm


protocol Renderer: class {
	var device: MTLDevice { get }
	init(device: MTLDevice)
}


extension Renderer {
	var library: MTLLibrary {
		return self.device.newDefaultLibrary()!
	}
}


class RendererRegistry {
	private var registory = [String: Renderer]()
	subscript(key: String) -> Renderer? {
		get { return registory[key] }
		set { registory[key] = newValue }
	}
}


func aligned(length: Int, alignment: Int) -> Int {
	return length + ((alignment - (length % alignment)) % alignment)
}
