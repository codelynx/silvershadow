//
//  SampleCanvas.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 12/28/16.
//  Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


class SampleCanvas: Canvas {

	override init?(device: MTLDevice, contentSize: CGSize) {
		super.init(device: device, contentSize: contentSize)
		/*
		let sampleCanvasLayer1 = SampleCanvasLayer1()
		self.addLayer(sampleCanvasLayer1)
		*/
		
		// having problem of compositing layers, so comment out this part for now
		let sampleCanvasLayer2 = SampleCanvasLayer2()
		self.addLayer(sampleCanvasLayer2)
	}

	override func render(in context: RenderContext) {
		super.render(in: context)
	}


	#if os(macOS)
	override func mouseDown(with event: NSEvent) {
		Swift.print("mouseDown:")
		if let location = self.locationInScene(event) {
			Swift.print("location=\(location)")
		}
		self.setNeedsUpdate()
	}
	#endif

}
