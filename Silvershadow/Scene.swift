//
//	RenderableContent.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/12/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


class Scene {

	let device: MTLDevice
	var contentSize: CGSize

	var backgroundColor: XColor = XColor.white {
		didSet { self.setNeedsDisplay() }
	}

	var width: CGFloat { return contentSize.width }
	var height: CGFloat { return contentSize.height }

	weak var renderView: RenderView?

	var bounds: CGRect {
        return CGRect(origin: .zero, size: contentSize)
	}
	
	init?(device: MTLDevice, contentSize: CGSize) {
		self.device = device
		self.contentSize = contentSize
	}

	func didMove(to renderView: RenderView) {
		self.renderView = renderView
	}

	var commandQueue: MTLCommandQueue? {
		return self.renderView?.commandQueue
	}

	private (set) var beingUpdated: Bool = false

	func setNeedsUpdate() {
		if self.beingUpdated == false {
			self.beingUpdated = true
			if let semaphore = self.renderView?.semaphore {
				semaphore.wait()
				defer { semaphore.signal() }
				self.update()
			}
			else {
				self.update()
			}
			self.beingUpdated = false
		}
	}
	
	func setNeedsDisplay() {
		self.renderView?.setNeedsDisplay()
	}

	var mipmapped: Bool {
		return false
	}

	var transform: CGAffineTransform {
		return bounds.transform(to: CGRect(-1, -1, 2, 2))
	}

	// MARK: -

	func update() {
	}

	func draw(in context: CGContext) {
	}

	func render(in context: RenderContext) {
	}

	#if os(iOS)
	func locationInScene(_ touch: UITouch) -> CGPoint? {
		guard let contentView = self.renderView?.contentView else { return nil }
		return touch.location(in: contentView)
	}
	#endif

	#if os(macOS)
	func locationInScene(_ event: NSEvent) -> CGPoint? {
        return renderView?.contentView.convert(event.locationInWindow, from: nil)
	}
	#endif

	// MARK: -

	#if os(iOS)
	func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
	}
	
	func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
	}
	
	func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
	}
	
	func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
	}
	#endif

	#if os(macOS)
	func mouseDown(with event: NSEvent) {
	}
	
	func mouseMoved(with event: NSEvent) {
	}
	
	func mouseDragged(with event: NSEvent) {
	}
	
	func mouseUp(with event: NSEvent) {
	}
	#endif

}
