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
        return renderView?.contentView
    }

    #if os(iOS)
    override func layoutSubviews() {
        super.layoutSubviews()
        assert(renderView != nil)
    }

    override func draw(_ layer: CALayer, in context: CGContext) {
        self.draw(in : context)
    }

    override func setNeedsDisplay() {
        self.layer.setNeedsDisplay()
        super.setNeedsDisplay()
    }

    #endif

    #if os(macOS)
    override func layout() {
        super.layout()
        self.wantsLayer = true
        self.layer?.backgroundColor = .clear
    }

    override func draw(_ dirtyRect: NSRect) {
        CGContext.current.map { self.draw(in: $0) }
    }

    override var isFlipped: Bool {
        return true
    }

    #endif

    // MARK: -

    func draw(in context: CGContext) {
        guard let contentView = contentView, let scene = renderView?.scene else { return }

        let target = contentView.convert(contentView.bounds, to: self)
        let transform = scene.bounds.transform(to: target)
        context.concatenate(transform)
        context.saveGState()

        #if os(iOS)
            UIGraphicsPushContext(context)
        #endif

        scene.draw(in: context)

        #if os(iOS)
            UIGraphicsPopContext()
        #endif
        
        context.restoreGState()
    }
}
