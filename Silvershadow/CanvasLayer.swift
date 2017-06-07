//
//	CanvasLayer.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/28/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import MetalKit

class CanvasLayer: Equatable {

	var name: String?

	weak var canvas: Canvas?
	var isHidden: Bool = false
	
	var device: MTLDevice? { return self.canvas?.device }
	
	var contentSize: CGSize? { return self.canvas?.contentSize }
	
	var bounds: CGRect? {
        return contentSize.map { CGRect(origin: .zero, size: $0) }
	}
	
	init() {
		self.canvas = nil
	}

	func didMoveTo(canvas: Canvas) {
		self.canvas = canvas
	}

	func render(context: RenderContext) {
	}

	static func == (lhs: CanvasLayer, rhs: CanvasLayer) -> Bool {
		return lhs === rhs
	}
	
}
