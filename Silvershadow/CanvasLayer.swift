//
//	CanvasLayer.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/28/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


class CanvasLayer: Equatable {

	weak var canvas: Canvas?
	var isHidden: Bool = false
	
	var device: MTLDevice? { return self.canvas?.device }
	
	var contentSize: CGSize? { return self.canvas?.contentSize }
	
	var bounds: CGRect? {
		guard let contentSize = self.contentSize else { return nil }
		return CGRect(0, 0, contentSize.width, contentSize.height)
	}
	
	init() {
		self.canvas = nil
	}

	func didMoveTo(canvas: Canvas) {
		self.canvas = canvas
	}

	func render(context: CanvasRenderContext) {
	}

	static func == (lhs: CanvasLayer, rhs: CanvasLayer) -> Bool {
		return lhs === rhs
	}
	
	
}
