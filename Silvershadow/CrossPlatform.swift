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
#elseif os(macOS)
import Cocoa
#endif



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

#endif



#if os(macOS)
extension NSBezierPath {

	func addLine(to point: CGPoint) { self.line(to: point) }

	public var cgPath: CGPath {
		let path = CGMutablePath()
		var points = [CGPoint](repeating: .zero, count: 3)
		for i in 0 ..< self.elementCount {
			let type = self.element(at: i, associatedPoints: &points)
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
#endif

#if os(iOS)
extension UIBezierPath {

	func line(to point: CGPoint) { self.addLine(to: point) }

}
#endif


#if os(macOS)
extension NSView {

	func setNeedsLayout() {
		self.layout()
	}
	
	func setNeedsDisplay() {
		self.setNeedsDisplay(self.bounds)
	}

	func sendSubview(toBack: NSView) {
		var subviews = self.subviews
		if let index = subviews.index(of: toBack) {
			subviews.remove(at: index)
			subviews.insert(toBack, at: 0)
			self.subviews = subviews
		}
	}
	
	func bringSubview(toFront: NSView) {
		var subviews = self.subviews
		if let index = subviews.index(of: toFront) {
			subviews.remove(at: index)
			subviews.append(toFront)
			self.subviews = subviews
		}
	}

	func replaceSubview(subview: NSView, with other: NSView) {
		var subviews = self.subviews
		if let index = subviews.index(of: subview) {
			subviews.remove(at: index)
			subviews.insert(other, at: index)
			self.subviews = subviews
		}
	}

}
#endif


#if os(macOS)
extension NSImage {

	// somehow OSX does not provide CGImage property
	var cgImage: CGImage? {
		if let data = self.tiffRepresentation,
		   let imageSource = CGImageSourceCreateWithData(data as CFData, nil) {
			if CGImageSourceGetCount(imageSource) > 0 {
				return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
			}
		}
		return nil
	}

}
#endif

typealias XRGBA = (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)

#if os(macOS)
extension NSColor {

	var ciColor: CIColor {
		return CIColor(cgColor: self.cgColor)
	}

}

#endif

extension XColor {

	var rgba: XRGBA {
		var (r, g, b, a) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
		#if os(iOS)
		self.getRed(&r, green: &g, blue: &b, alpha: &a)
		return (r, g, b, a)
		#elseif os(macOS)
		let ciColor = CIColor(color: self)!
		return (ciColor.red, ciColor.green, ciColor.blue, ciColor.alpha)
		#endif
	}

	convenience init(rgba: XRGBA) {
		self.init(red: rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a)
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


