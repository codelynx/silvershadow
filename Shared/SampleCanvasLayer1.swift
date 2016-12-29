//
//  SampleCanvasLayer.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 12/28/16.
//  Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


class SampleCanvasLayer1: CanvasLayer {

	lazy var imageRenderable: ImageRenderable? = {
		guard let device = self.device else { return nil }
		guard let image = XImage(named: "BlueMarble.png") else { fatalError("not found") }
		return ImageRenderable(device: device, image: image, frame: Rect(0, 0, 2048, 1024))!
	}()

	override func render(context: RenderContext) {
		self.imageRenderable?.render(context: context)
	}

}

