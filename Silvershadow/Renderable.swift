//
//	Renderable.swift
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


fileprivate var deviceRendererMap = NSMapTable<MTLDevice, RendererRegistry>.weakToStrongObjects()


protocol Renderable: class {

	associatedtype RendererType: Renderer
	var device: MTLDevice { get }
	var renderer: RendererType { get }
	func render(context: RenderContext)

}


extension Renderable {
	var renderer: RendererType {
		let device = self.device
		let key = NSStringFromClass(RendererType.self)
		let registry = deviceRendererMap.object(forKey: device) ?? RendererRegistry()
		let renderer = registry[key] ?? RendererType(device: device)
		registry[key] = renderer
		deviceRendererMap.setObject(registry, forKey: device)
		return renderer as! RendererType
	}
}


extension MTLDevice {

	func renderer<T: Renderer>() -> T {
		let key = NSStringFromClass(T.self)
		let registry = deviceRendererMap.object(forKey: self) ?? RendererRegistry()
		let renderer = registry[key] ?? T(device: self)
		registry[key] = renderer
		deviceRendererMap.setObject(registry, forKey: self)
		return renderer as! T
	}

}



