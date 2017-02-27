//
//	SampleScene.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/25/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

import CoreGraphics
import MetalKit
import GLKit


class SampleScene: Scene {

	lazy var colorTriangle: ColorTriangleRenderable? = {
		let pt1 = ColorRenderer.Vertex(x: 0, y: 0, z: 0, w: 1, r: 1, g: 0, b: 0, a: 0.5)
		let pt2 = ColorRenderer.Vertex(x: 1024, y: 1024, z: 0, w: 1, r: 0, g: 1, b: 0, a: 0.5)
		let pt3 = ColorRenderer.Vertex(x: 2048, y: 0, z: 0, w: 1, r: 0, g: 0, b: 1, a: 0.5)
		return ColorTriangleRenderable(device: self.device, point1: pt1, point2: pt2, point3: pt3)
	}()

	lazy var image1Texture: MTLTexture = {
		return self.device.texture(of: XImage(named: "BlueMarble")!)!
	}()

	// MRAK: -

	override func draw(in context: CGContext) {
/*
		context.saveGState()
		context.setFillColor(XColor.orange.cgColor)
		context.strokeEllipse(in: self.bounds.insetBy(dx: 100, dy: 100))
		context.restoreGState()

		XColor.red.set()
		let bezier = XBezierPath(ovalIn: self.bounds)
		bezier.stroke()
	
		XColor.red.set()
		XBezierPath(ovalIn: CGRect(0, 0, self.bounds.width * 0.5, self.bounds.height * 0.5)).stroke()
*/
	}

	override func render(in context: RenderContext) {
		context.render(texture: self.image1Texture, in: Rect(0, 0, 2048, 1024))
		self.colorTriangle?.render(context: context)
	}

	#if os(macOS)
	override func mouseDown(with event: NSEvent) {
		Swift.print("mouseDown:")
		if let location = self.locationInScene(event) {
			Swift.print("location=\(location)")
		}
	}
	#endif

}

