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




protocol Renderable: class {

	associatedtype RendererType: Renderer
	var device: MTLDevice { get }
	var renderer: RendererType { get }
	func render(context: RenderContext)

}


extension Renderable {
	var renderer: RendererType {
		let renderer = self.device.renderer() as RendererType
		return renderer
	}
}





