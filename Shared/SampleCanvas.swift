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

	var drawingLayer = SampleCanvasScribbleLayer()
	var interactiveLayer = SampleCanvasScribbleLayer()

	override init?(device: MTLDevice, contentSize: CGSize) {
		super.init(device: device, contentSize: contentSize)

		let backdropLayer = SampleCanvasBackdropLayer()
		self.addLayer(backdropLayer)
		
		// having problem of compositing layers, so comment out this part for now
		self.addLayer(drawingLayer)
	}

	override func render(in context: RenderContext) {
		super.render(in: context)
	}

	override func didMove(to renderView: RenderView) {
		super.didMove(to: renderView)
		self.overlayCanvasLayer = interactiveLayer
		
		self.interactiveLayer.name = "overlay"
		self.drawingLayer.name = "drawing"
	}

	#if os(macOS)
	var activePath: CGMutablePath?

	override func mouseDown(with event: NSEvent) {
		if let location = self.locationInScene(event) {
			let activePath = CGMutablePath()
			activePath.move(to: location)
			self.interactiveLayer.strokePaths.append(activePath)
			self.activePath = activePath
		}
	}

	override func mouseDragged(with event: NSEvent) {
		if let activePath = self.activePath, let location = self.locationInScene(event) {
			activePath.addLine(to: location)
			self.setNeedsDisplay()
		}
	}

	override func mouseUp(with event: NSEvent) {
		if let activePath = self.activePath {
			if let location = self.locationInScene(event) {
				activePath.addLine(to: location)
			}
			drawingLayer.strokePaths.append(activePath)
			self.interactiveLayer.strokePaths = []
			self.setNeedsUpdate()
			self.setNeedsDisplay()
		}
		self.activePath = nil
	}

	#endif
	
	#if os(iOS)
	var activeTouchPath: (touch: UITouch, path: CGMutablePath)?
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let touch = touches.first, touches.count == 1, let location = self.locationInScene(touch) {
			let activePath = CGMutablePath()
			activePath.move(to: location)
			self.interactiveLayer.strokePaths.append(activePath)
			self.activeTouchPath = (touch, activePath)
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let (touch, activePath) = self.activeTouchPath, touches.contains(touch) {
			if let event = event, let coalescedTouches = event.coalescedTouches(for: touch) {
				for coalescedTouch in coalescedTouches {
					if let location = self.locationInScene(coalescedTouch) {
						activePath.addLine(to: location)
					}
				}
			}
			self.setNeedsDisplay()
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let (touch, activePath) = self.activeTouchPath, touches.contains(touch) {
			if let event = event, let coalescedTouches = event.coalescedTouches(for: touch) {
				for coalescedTouch in coalescedTouches {
					if let location = self.locationInScene(coalescedTouch) {
						activePath.addLine(to: location)
					}
				}
			}
			drawingLayer.strokePaths.append(activePath)
			self.interactiveLayer.strokePaths = []
			self.setNeedsUpdate()
			self.setNeedsDisplay()
		}
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.interactiveLayer.strokePaths = []
		self.setNeedsUpdate()
		self.setNeedsDisplay()
		self.activeTouchPath = nil
	}
	
	#endif

}
