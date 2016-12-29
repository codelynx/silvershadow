//
//	RenderDrawView.swift
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


class RenderDrawView: XView {

	var renderView: RenderView?
	
	var contentView: RenderContentView? {
		return self.renderView?.contentView
	}

	#if os(iOS)
	override func layoutSubviews() {
		super.layoutSubviews()
		assert(renderView != nil)
	}
	#endif

	#if os(macOS)
	override func layout() {
		super.layout()
		self.wantsLayer = true
		self.layer?.backgroundColor = .clear
	}
	#endif

	// MARK: -

	#if os(iOS)
	override func draw(_ layer: CALayer, in context: CGContext) {
		if let contentView = contentView, let renderableScene = renderView?.scene  {
			let targetRect = contentView.convert(contentView.bounds, to: self)
			let transform = renderableScene.bounds.transform(to: targetRect)
			context.concatenate(transform)

			context.saveGState()
			UIGraphicsPushContext(context)
			renderableScene.draw(in: context)
			UIGraphicsPopContext()
			context.restoreGState()
		}
	}
	#endif

	#if os(macOS)
	override func draw(_ dirtyRect: NSRect) {
		if let contentView = contentView, let renderableScene = renderView?.scene, let graphicsContext = NSGraphicsContext.current() {
			let context = graphicsContext.cgContext

			let targetRect = contentView.convert(contentView.bounds, to: self)
			let transform = renderableScene.bounds.transform(to: targetRect)

			context.concatenate(transform)
			context.saveGState()

			renderableScene.draw(in: context)

			context.restoreGState()
		}
	}
	#endif

	#if os(macOS)
	override var isFlipped: Bool {
		return true
	}
	#endif

	#if os(iOS)
	override func setNeedsDisplay() {
		self.layer.setNeedsDisplay()
		super.setNeedsDisplay()
	}
	#endif

}
