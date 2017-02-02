//
//  CGPath+Z.swift [swift3.0]
//  ZKit
//
//	The MIT License (MIT)
//
//	Copyright (c) 2016 Electricwoods LLC, Kaz Yoshikawa.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy 
//	of this software and associated documentation files (the "Software"), to deal 
//	in the Software without restriction, including without limitation the rights 
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
//	copies of the Software, and to permit persons to whom the Software is 
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in 
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.
//


import Foundation
import CoreGraphics

//
//	PathElement
//

public enum PathElement {
	case moveTo(CGPoint)
	case lineTo(CGPoint)
	case quadCurveTo(CGPoint, CGPoint)
	case curveTo(CGPoint, CGPoint, CGPoint)
	case closeSubpath
}


//
//	CGPathRef
//

public extension CGPath {

	private class Elements {
		var pathElements = [PathElement]()
	}

	var pathElements: [PathElement] {
		var elements = Elements()

		self.apply(info: &elements) { (info, element) -> Void in
		
			if let infoPointer = UnsafeMutablePointer<Elements>(OpaquePointer(info)) {
				switch element.pointee.type {
				case .moveToPoint:
					let pt = element.pointee.points[0]
					infoPointer.pointee.pathElements.append(PathElement.moveTo(pt))
				case .addLineToPoint:
					let pt = element.pointee.points[0]
					infoPointer.pointee.pathElements.append(PathElement.lineTo(pt))
				case .addQuadCurveToPoint:
					let pt1 = element.pointee.points[0]
					let pt2 = element.pointee.points[1]
					infoPointer.pointee.pathElements.append(PathElement.quadCurveTo(pt1, pt2))
				case .addCurveToPoint:
					let pt1 = element.pointee.points[0]
					let pt2 = element.pointee.points[1]
					let pt3 = element.pointee.points[2]
					infoPointer.pointee.pathElements.append(PathElement.curveTo(pt1, pt2, pt3))
				case .closeSubpath:
					infoPointer.pointee.pathElements.append(PathElement.closeSubpath)
				}
			}
		}

		let pathelements = elements.pathElements
		return pathelements
	}

}

//
//	operator ==
//

public func == (lhs: PathElement, rhs: PathElement) -> Bool {
	switch (lhs, rhs) {
	case (.moveTo(let a), .moveTo(let b)):
		return a == b
	case (.lineTo(let a), .lineTo(let b)):
		return a == b
	case (.quadCurveTo(let a1, let a2), .quadCurveTo(let b1, let b2)):
		return a1.equalTo(b1) && a2.equalTo(b2)
	case (.curveTo(let a1, let a2, let a3), .curveTo(let b1, let b2, let b3)):
		return a1 == b1 && a2 == b2 && a3 == b3
	case (.closeSubpath, .closeSubpath):
		return true
	default:
		return false
	}
}


