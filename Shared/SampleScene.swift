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


class SampleScene: Scene {

	lazy var colorTriangle: ColorTriangleRenderable? = {
		let pt1 = ColorRenderer.Vertex(x: 0, y: 0, z: 0, w: 1, r: 1, g: 0, b: 0, a: 0.5)
		let pt2 = ColorRenderer.Vertex(x: 1024, y: 1024, z: 0, w: 1, r: 0, g: 1, b: 0, a: 0.5)
		let pt3 = ColorRenderer.Vertex(x: 2048, y: 0, z: 0, w: 1, r: 0, g: 0, b: 1, a: 0.5)
		return ColorTriangleRenderable(device: self.device, point1: pt1, point2: pt2, point3: pt3)
	}()

	lazy var image1Texture: MTLTexture = {
		return self.device.texture(of: XImage(named: "BlueMarble.png")!)!
	}()

	lazy var pointTexture: MTLTexture = {
		return self.device.texture(of: XImage(named: "Particle.png")!)!
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

		typealias Vertex =  ColorRenderer.Vertex
		context.render(triangles: [(
			Vertex(x: 1024, y: 512, z: 0, w: 1, r: 1, g: 0, b: 0, a: 0.5),
			Vertex(x: 2048, y: 0, z: 0, w: 1, r: 0, g: 1, b: 0, a: 0.5),
			Vertex(x: 2048, y: 1024, z: 0, w: 1, r: 0, g: 0, b: 1, a: 0.5)
		),(
			Vertex(x: 1024, y: 512, z: 0, w: 1, r: 1, g: 0, b: 0, a: 0.5),
			Vertex(x: 0, y: 0, z: 0, w: 1, r: 0, g: 1, b: 0, a: 0.5),
			Vertex(x: 0, y: 1024, z: 0, w: 1, r: 0, g: 0, b: 1, a: 0.5)
		)])

		let pointTexture = self.pointTexture
		let points: [(CGFloat, CGFloat)] = [
			(342.0, 611.5), (328.0, 616.0), (319.0, 616.0), (307.5, 617.5), (293.5, 619.5), (278.5, 620.5), (262.0, 621.5), (246.5, 621.5), (230.5, 621.5),
			(212.0, 619.5), (195.0, 615.5), (179.5, 610.0), (165.0, 603.0), (151.0, 595.0), (138.0, 585.5), (127.0, 575.0), (117.0, 564.0), (109.0, 552.0),
			(103.0, 539.5), (100.0, 526.5), (99.5, 511.0), (100.0, 492.5), (107.0, 474.5), (118.5, 453.5), (132.0, 434.0), (149.0, 415.5), (169.5, 396.5),
			(194.0, 378.0), (221.5, 361.5), (251.0, 348.5), (280.0, 339.5), (307.5, 333.5), (336.0, 332.5), (365.0, 333.0), (393.5, 340.0), (418.5, 352.0),
			(442.0, 367.0), (463.0, 384.0), (481.0, 402.5), (495.5, 422.5), (506.5, 443.0), (513.5, 464.0), (517.0, 483.0), (518.5, 503.0), (518.5, 522.5),
			(513.0, 541.0), (502.0, 560.0), (488.0, 576.0), (470.5, 591.0), (451.5, 604.5), (429.5, 616.0), (405.5, 625.0), (381.0, 632.5), (357.0, 638.5),
			(333.0, 642.5), (308.5, 644.0), (286.5, 644.5), (263.5, 644.5), (241.5, 642.5), (221.5, 637.0), (204.5, 631.5), (191.5, 625.5), (181.5, 621.0),
			(174.5, 614.5)
		]
		context.render(points: points.map { Point(x: $0.0, y: $0.1) }, texture: pointTexture, width: 32)
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

