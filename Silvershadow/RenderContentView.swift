//
//	RenderContentView.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/12/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

class RenderContentView: XView {

	weak var renderView: RenderView?

	var contentSize: CGSize? {
		return self.renderView?.scene?.contentSize
	}

	override func draw(_ rect: CGRect) {
		super.draw(rect)
	}

	#if os(iOS)
	override func layoutSubviews() {
		super.layoutSubviews()
	}
	#endif

	#if os(macOS)
	override func layout() {
		super.layout()
	}
	#endif

	#if os(macOS)
	override var isFlipped: Bool {
		return true
	}
	#endif


	// MARK: -

	#if os(iOS)
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		renderView?.scene?.touchesBegan(touches, with: event)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		renderView?.scene?.touchesMoved(touches, with: event)
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		renderView?.scene?.touchesEnded(touches, with: event)
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		renderView?.scene?.touchesCancelled(touches, with: event)
	}
	#endif

	#if os(macOS)
	override func mouseDown(with event: NSEvent) {
		renderView?.scene?.mouseDown(with: event)
	}
	
	override func mouseMoved(with event: NSEvent) {
		renderView?.scene?.mouseMoved(with: event)
	}
	
	override func mouseDragged(with event: NSEvent) {
		renderView?.scene?.mouseDragged(with: event)
	}
	
	override func mouseUp(with event: NSEvent) {
		renderView?.scene?.mouseUp(with: event)
	}
	#endif

}
