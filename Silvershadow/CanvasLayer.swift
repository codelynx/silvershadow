//
//  CanvasLayer.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 12/28/16.
//  Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


class CanvasLayer: Equatable {

	weak var canvas: Canvas?
	var isHidden: Bool = false
	
	var device: MTLDevice? { return self.canvas?.device }
	
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
