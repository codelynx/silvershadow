//
//  BezierRenderer.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 1/7/17.
//  Copyright © 2017 Electricwoods LLC. All rights reserved.
//

import Foundation
import CoreGraphics
import QuartzCore
import GLKit



extension RenderContext {

	func render(cgPath: CGPath, texture: MTLTexture, width: Float) {
	
		let kernel: BezierKernel = self.device.kernel()
		_ = kernel.compute(self.commandBuffer.commandQueue, cgPath)
	
	}

}
