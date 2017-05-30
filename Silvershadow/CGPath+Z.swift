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

	//
	//	operator ==
	//

	static public func ==(lhs: PathElement, rhs: PathElement) -> Bool {
		switch (lhs, rhs) {
		case let (.moveTo(l), .moveTo(r)),
		     let (.lineTo(l), .lineTo(r)):
			return l == r
		case let (.quadCurveTo(l), .quadCurveTo(r)):
			return l == r
		case let (.curveTo(l), .curveTo(r)):
			return l == r
		case (.closeSubpath, .closeSubpath):
			return true
		default:
			return false
		}
	}
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

		self.apply(info: &elements) { (info, element) -> () in
			guard let infoPointer = UnsafeMutablePointer<Elements>(OpaquePointer(info)) else { return }
			switch element.pointee.type {
			case .moveToPoint:
				let pt = element.pointee.points[0]
				infoPointer.pointee.pathElements.append(.moveTo(pt))
			case .addLineToPoint:
				let pt = element.pointee.points[0]
				infoPointer.pointee.pathElements.append(.lineTo(pt))
			case .addQuadCurveToPoint:
				let pt1 = element.pointee.points[0]
				let pt2 = element.pointee.points[1]
				infoPointer.pointee.pathElements.append(.quadCurveTo(pt1, pt2))
			case .addCurveToPoint:
				let pt1 = element.pointee.points[0]
				let pt2 = element.pointee.points[1]
				let pt3 = element.pointee.points[2]
				infoPointer.pointee.pathElements.append(.curveTo(pt1, pt2, pt3))
			case .closeSubpath:
				infoPointer.pointee.pathElements.append(.closeSubpath)
			}
		}

		let pathelements = elements.pathElements
		return pathelements
	}
}


//
//
//

extension CGPath {

	static func quadraticCurveLength(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint) -> CGFloat {

		// cf. http://www.malczak.linuxpl.com/blog/quadratic-bezier-curve-length/

		let a = CGPoint(p0.x - 2 * p1.x + p2.x, p0.y - 2 * p1.y + p2.y)
		let b = CGPoint(2 * p1.x - 2 * p0.x, 2 * p1.y - 2 * p0.y)
		let A = 4 * (a.x * a.x + a.y * a.y)
		let B = 4 * (a.x * b.x + a.y * b.y)
		let C = b.x * b.x + b.y * b.y
		let Sabc = 2 * sqrt(A + B + C)
		let A_2 = sqrt(A)
		let A_32 = 2 * A * A_2
		let C_2 = 2 * sqrt(C)
		let BA = B / A_2
		let L = (A_32 * Sabc + A_2 * B * (Sabc - C_2) + (4 * C * A - B * B) * log((2 * A_2 + BA + Sabc) / (BA + C_2))) / (4 * A_32)
		return L.isNaN ? 0 : L
	}

	static func approximateCubicCurveLength(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
		let n = 32
		var length: CGFloat = 0
		var point: CGPoint? = nil
		for i in 0 ..< n {
			let t = CGFloat(i) / CGFloat(n)

			let q1 = p0 + (p1 - p0) * t
			let q2 = p1 + (p2 - p1) * t
			let q3 = p2 + (p3 - p2) * t

			let r1 = q1 + (q2 - q1) * t
			let r2 = q2 + (q3 - q2) * t

			let s = r1 + (r2 - r1) * t

			if let point = point {
				length += (point - s).length
			}
			point = s
		}
		return length
	}

}


