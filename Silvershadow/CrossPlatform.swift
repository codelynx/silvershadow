//
//	CrossPlatform.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/25/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation


#if os(iOS)

    import UIKit
    typealias XView = UIView
    typealias XImage = UIImage
    typealias XColor = UIColor
    typealias XBezierPath = UIBezierPath
    typealias XScrollView = UIScrollView
    typealias XScrollViewDelegate = UIScrollViewDelegate
    typealias XViewController = UIViewController
    typealias XFont = UIFont

    extension UIBezierPath {
        func line(to point: CGPoint) {
            addLine(to: point)
        }
    }


#elseif os(macOS)

    import Cocoa
    typealias XView = NSView
    typealias XImage = NSImage
    typealias XColor = NSColor
    typealias XBezierPath = NSBezierPath
    typealias XScrollView = NSScrollView
    typealias XViewController = NSViewController
    typealias XFont = NSFont

    protocol XScrollViewDelegate {}


    extension NSBezierPath {

        func addLine(to point: CGPoint) {
            line(to: point)
        }

        public var cgPath: CGPath {
            let path = CGMutablePath()
            var points = [CGPoint](repeating: .zero, count: 3)
            for i in 0 ..< elementCount {
                let type = element(at: i, associatedPoints: &points)
                switch type {
                case .moveToBezierPathElement: path.move(to: points[0])
                case .lineToBezierPathElement: path.addLine(to: points[0])
                case .curveToBezierPathElement: path.addCurve(to: points[2], control1: points[0], control2: points[1])
                case .closePathBezierPathElement: path.closeSubpath()
                }
            }
            return path
        }

    }

    extension NSView {

        func setNeedsLayout() {
            layout()
        }

        func setNeedsDisplay() {
            setNeedsDisplay(bounds)
        }

        func sendSubview(toBack: NSView) {
            var subviews = self.subviews
            guard let index = subviews.index(of: toBack) else { return }
            subviews.remove(at: index)
            subviews.insert(toBack, at: 0)
            self.subviews = subviews
        }

        func bringSubview(toFront: NSView) {
            var subviews = self.subviews
            guard let index = subviews.index(of: toFront) else { return }
            subviews.remove(at: index)
            subviews.append(toFront)
            self.subviews = subviews
        }

        func replaceSubview(subview: NSView, with other: NSView) {
            var subviews = self.subviews
            guard let index = subviews.index(of: subview) else { return }
            subviews.remove(at: index)
            subviews.insert(other, at: index)
            self.subviews = subviews
        }
    }

    extension NSImage {
        // somehow OSX does not provide CGImage property

        var cgImage: CGImage? {
            return cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
    }

    extension CGContext {
        static var current : CGContext? {
            return NSGraphicsContext.current()?.cgContext
        }
    }

    extension NSScrollView {
        var zoomScale : CGFloat {
            return magnification
        }
    }

#endif

struct XRGBA {
    let r,g,b,a: CGFloat

    init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    init(ciColor : CIColor) {
        self.init(r: ciColor.red, g: ciColor.green, b: ciColor.blue, a: ciColor.alpha)
    }

    init() {
        self.init(r: 0, g: 0, b: 0, a: 0)
    }

    init(color: XColor) {
        self.init(ciColor: CIColor(color: color)!)
    }
}

extension XColor {

    var rgba: XRGBA {
        return .init(color: self)
    }

}

extension NSMutableParagraphStyle {

    static func makeParagraphStyle() -> NSMutableParagraphStyle {
        #if os(iOS)
            return NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        #elseif os(macOS)
            return NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
        #endif
    }
}


