//
//	GeoUtils.swift
//	ZKit
//
//	Created by Kaz Yoshikawa on 1/4/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import CoreGraphics
import QuartzCore
import GLKit
import simd

infix operator •
infix operator ×


// MARK: -

protocol FloatCovertible {
	var floatValue: Float { get }
}

extension CGFloat: FloatCovertible {
	var floatValue: Float { return Float(self) }
}

extension Int: FloatCovertible {
	var floatValue: Float { return Float(self) }
}

extension Float: FloatCovertible {
	var floatValue: Float { return self }
}

// MARK: -

protocol CGFloatCovertible {
	var cgFloatValue: CGFloat { get }
}

extension CGFloat: CGFloatCovertible {
	var cgFloatValue: CGFloat { return self }
}

extension Int: CGFloatCovertible {
	var cgFloatValue: CGFloat { return CGFloat(self) }
}

extension Float: CGFloatCovertible {
	var cgFloatValue: CGFloat { return CGFloat(self) }
}



// MARK: -

struct Point: Hashable, CustomStringConvertible {

	var x: Float
	var y: Float

	static func - (lhs: Point, rhs: Point) -> Point {
		return Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
	}

	static func + (lhs: Point, rhs: Point) -> Point {
		return Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
	}

	static func * (lhs: Point, rhs: Float) -> Point {
		return Point(x: lhs.x * rhs, y: lhs.y * rhs)
	}

	static func / (lhs: Point, rhs: Float) -> Point {
		return Point(x: lhs.x / rhs, y: lhs.y / rhs)
	}
	
	static func • (lhs: Point, rhs: Point) -> Float { // dot product
		return lhs.x * rhs.x + lhs.y * rhs.y
	}

	static func × (lhs: Point, rhs: Point) -> Float { // cross product
		return lhs.x * rhs.y - lhs.y * rhs.x
	}

	init<X: FloatCovertible, Y: FloatCovertible>(_ x: X, _ y: Y) {
		self.x = x.floatValue
		self.y = y.floatValue
	}
	init<X: FloatCovertible, Y: FloatCovertible>(x: X, y: Y) {
		self.x = x.floatValue
		self.y = y.floatValue
	}
	init(_ point: CGPoint) {
		self.x = Float(point.x)
		self.y = Float(point.y)
	}
	
	var length²: Float {
		return (x * x) + (y * y)
	}

	var length: Float {
		return sqrt(self.length²)
	}

	var normalized: Point {
		let length = self.length
		return Point(x: x/length, y: y/length)
	}

	func angle(to: Point) -> Float {
		return atan2(to.y - self.y, to.x - self.x)
	}

	func angle(from: Point) -> Float {
		return atan2(self.y - from.y, self.x - from.x)
	}

	var hashValue: Int { return self.x.hashValue &- self.y.hashValue }

	static func == (lhs: Point, rhs: Point) -> Bool {
		return lhs.x == rhs.y && lhs.y == rhs.y
	}
	
	var description: String {
		return "(x:\(x), y:\(y))"
	}
}


struct Size: CustomStringConvertible {
	var width: Float
	var height: Float

	init<W: FloatCovertible, H: FloatCovertible>(_ width: W, _ height: H) {
		self.width = width.floatValue
		self.height = height.floatValue
	}

	init<W: FloatCovertible, H: FloatCovertible>(width: W, height: H) {
		self.width = width.floatValue
		self.height = height.floatValue
	}
	init(_ size: CGSize) {
		self.width = Float(size.width)
		self.height = Float(size.height)
	}
	var description: String {
		return "(w:\(width), h:\(height))"
	}
}


struct Rect: CustomStringConvertible {
	var origin: Point
	var size: Size

	init(origin: Point, size: Size) {
		self.origin = origin; self.size = size
	}
	init(_ origin: Point, _ size: Size) {
		self.origin = origin; self.size = size
	}
	init<X: FloatCovertible, Y: FloatCovertible, W: FloatCovertible, H: FloatCovertible>(_ x: X, _ y: Y, _ width: W, _ height: H) {
		self.origin = Point(x: x, y: y)
		self.size = Size(width: width, height: height)
	}
	init<X: FloatCovertible, Y: FloatCovertible, W: FloatCovertible, H: FloatCovertible>(x: X, y: Y, width: W, height: H) {
		self.origin = Point(x: x, y: y)
		self.size = Size(width: width, height: height)
	}
	init(_ rect: CGRect) {
		self.origin = Point(rect.origin)
		self.size = Size(rect.size)
	}

	var minX: Float { return min(origin.x, origin.x + size.width) }
	var maxX: Float { return max(origin.x, origin.x + size.width) }
	var midX: Float { return (origin.x + origin.x + size.width) / 2.0 }
	var minY: Float { return min(origin.y, origin.y + size.height) }
	var maxY: Float { return max(origin.y, origin.y + size.height) }
	var midY: Float { return (origin.y + origin.y + size.height) / 2.0 }

	var cgRectValue: CGRect { return CGRect(x: CGFloat(origin.x), y: CGFloat(origin.y), width: CGFloat(size.width), height: CGFloat(size.height)) }
	var description: String { return "{Rect: (\(origin.x),\(origin.y))-(\(size.width), \(size.height))}" }
}

// MARK: -

protocol PointConvertible {
	var pointValue: Point { get }
}

extension Point: PointConvertible {
	var pointValue: Point { return self }
}

extension CGPoint: PointConvertible {
	var pointValue: Point { return Point(self) }
}


// MARK: -

extension CGPoint {

	init(_ point: Point) {
		self.init(x: CGFloat(point.x), y: CGFloat(point.y))
	}

	static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
	}

	static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
	}

	static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
		return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
	}

	static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
		return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
	}
	
	static func • (lhs: CGPoint, rhs: CGPoint) -> CGFloat { // dot product
		return lhs.x * rhs.x + lhs.y * rhs.y
	}

	static func × (lhs: CGPoint, rhs: CGPoint) -> CGFloat { // cross product
		return lhs.x * rhs.y - lhs.y * rhs.x
	}
	
	var length²: CGFloat {
		return (x * x) + (y * y)
	}

	var length: CGFloat {
		return sqrt(self.length²)
	}

	var normalized: CGPoint {
		return self / length
	}
}

extension CGPoint {
	init<X: CGFloatCovertible, Y: CGFloatCovertible>(_ x: X, _ y: Y) {
		self.x = x.cgFloatValue
		self.y = y.cgFloatValue
	}
}


extension CGSize {
	init(_ size: Size) {
		self.init(width: CGFloat(size.width), height: CGFloat(size.height))
	}

	init<W: CGFloatCovertible, H: CGFloatCovertible>(_ width: W, _ height: H) {
		self.width = width.cgFloatValue
		self.height = height.cgFloatValue
	}
}

extension CGRect {
	init(_ rect: Rect) {
		self.init(origin: CGPoint(rect.origin), size: CGSize(rect.size))
	}

	init<X: CGFloatCovertible, Y: CGFloatCovertible, W: CGFloatCovertible, H: CGFloatCovertible>(_ x: X, _ y: Y, _ width: W, _ height: H) {
		self.origin = CGPoint(x, y)
		self.size = CGSize(width, height)
	}
}

extension GLKMatrix4: CustomStringConvertible, Collection {
    public typealias Index = Int

    static let identity : GLKMatrix4 = GLKMatrix4Identity

    public var startIndex : Index {
        return 0
    }

    public var endIndex : Index {
        return 16
    }

    public func index(after i: Index) -> Index {
        return i + 1
    }

    init(_ transform: CGAffineTransform) {
		let t = CATransform3DMakeAffineTransform(transform)
		self.init(m: (Float(t.m11), Float(t.m12), Float(t.m13), Float(t.m14),
		              Float(t.m21), Float(t.m22), Float(t.m23), Float(t.m24),
		              Float(t.m31), Float(t.m32), Float(t.m33), Float(t.m34),
		              Float(t.m41), Float(t.m42), Float(t.m43), Float(t.m44)))
	}

    var scaleFactor : Float {
		return sqrt(m00 * m00 + m01 * m01 + m02 * m02)
	}

    var invert: GLKMatrix4? {
		var invertible: Bool = true
		let t = GLKMatrix4Invert(self, &invertible)
        return invertible ? t : nil
	}

    public var description: String {
        return map { "\($0)" }.joined(separator: ",")
	}

	static func * (l: GLKMatrix4, r: GLKMatrix4) -> GLKMatrix4 {
		return GLKMatrix4Multiply(l, r)
	}
}

extension GLKVector2: CustomStringConvertible {
	init(_ point: CGPoint) {
		self.init(v: (Float(point.x), Float(point.y)))
	}
	public var description: String {
		return	"[ \(self.x), \(self.y) ]"
	}
	static func + (l: GLKVector2, r: GLKVector2) -> GLKVector2 {
		return GLKVector2Add(l, r)
	}
}


extension GLKVector4: CustomStringConvertible {
	public var description: String {
		return	"[ \(self.x), \(self.y), \(self.z), \(self.w) ]"
	}
}


func * (l: GLKMatrix4, r: GLKVector2) -> GLKVector2 {
	let vector4 = GLKMatrix4MultiplyVector4(l, GLKVector4Make(r.x, r.y, 0.0, 1.0))
	return GLKVector2Make(vector4.x, vector4.y)
}

extension float2 {
	init(_ vector: GLKVector2) {
		self = unsafeBitCast(vector, to: float2.self)
	}
}

extension float3 {
	init(_ vector: GLKVector3) {
		self = unsafeBitCast(vector, to: float3.self)
	}
}

extension float4 {
	init(_ vector: GLKVector4) {
		self = unsafeBitCast(vector, to: float4.self)
	}
}

extension float2x2 {
	init(_ matrix: GLKMatrix2) {
		self = unsafeBitCast(matrix, to: float2x2.self)
	}
}

extension float3x3 {
	init(_ matrix: GLKMatrix3) {
		self = unsafeBitCast(matrix, to: float3x3.self)
	}
}

extension float4x4 {
	init(_ matrix: GLKMatrix4) {
		self = unsafeBitCast(matrix, to: float4x4.self)
	}
}

extension MTLClearColor : Equatable {
    public static func ==(lhs: MTLClearColor, rhs: MTLClearColor) -> Bool {
        return lhs.red == rhs.red && lhs.green == rhs.green &&
               lhs.blue == rhs.blue && lhs.alpha == rhs.alpha
    }
}

