//
//  Float16.swift
//  ZKit
//
//  Created by Kaz Yoshikawa on 2/2/17.
//  Copyright © 2017 Electricwoods LLC. All rights reserved.
//

import Foundation
import Accelerate

struct Float16: CustomStringConvertible {

    var rawValue: UInt16

    static func float_to_float16(value: Float) -> UInt16 {
        var input: [Float] = [value]
        var output: [UInt16] = [0]
        var sourceBuffer = vImage_Buffer(data: &input, height: 1, width: 1, rowBytes: MemoryLayout<Float>.size)
        var destinationBuffer = vImage_Buffer(data: &output, height: 1, width: 1, rowBytes: MemoryLayout<UInt16>.size)
        vImageConvert_PlanarFtoPlanar16F(&sourceBuffer, &destinationBuffer, 0)
        return output[0]
    }

    static func float16_to_float(value: UInt16) -> Float {
        var input: [UInt16] = [value]
        var output: [Float] = [0]
        var sourceBuffer = vImage_Buffer(data: &input, height: 1, width: 1, rowBytes: MemoryLayout<UInt16>.size)
        var destinationBuffer = vImage_Buffer(data: &output, height: 1, width: 1, rowBytes: MemoryLayout<Float>.size)
        vImageConvert_Planar16FtoPlanarF(&sourceBuffer, &destinationBuffer, 0)
        return output[0]
    }

    static func floats_to_float16s(values: [Float]) -> [UInt16] {
        var inputs = values
        var outputs = Array<UInt16>(repeating: 0, count: values.count)
		let width = vImagePixelCount(values.count)
        var sourceBuffer = vImage_Buffer(data: &inputs, height: 1, width: width, rowBytes: MemoryLayout<Float>.size * values.count)
        var destinationBuffer = vImage_Buffer(data: &outputs, height: 1, width: width, rowBytes: MemoryLayout<UInt16>.size * values.count)
        vImageConvert_PlanarFtoPlanar16F(&sourceBuffer, &destinationBuffer, 0)
        return outputs
    }

    static func float16s_to_floats(values: [UInt16]) -> [Float] {
        var inputs: [UInt16] = values
        var outputs: [Float] = Array<Float>(repeating: 0, count: values.count)
		let width = vImagePixelCount(values.count)
        var sourceBuffer = vImage_Buffer(data: &inputs, height: 1, width: width, rowBytes: MemoryLayout<UInt16>.size * values.count)
        var destinationBuffer = vImage_Buffer(data: &outputs, height: 1, width: width, rowBytes: MemoryLayout<Float>.size * values.count)
        vImageConvert_Planar16FtoPlanarF(&sourceBuffer, &destinationBuffer, 0)
        return outputs
    }

    init(_ value: Float) {
        self.rawValue = Float16.float_to_float16(value: value)
    }

    var floatValue: Float {
        return Float16.float16_to_float(value: self.rawValue)
    }

    var description: String {
        return floatValue.description
    }

	static func + (lhs: Float16, rhs: Float16) -> Float16 {
		return Float16(lhs.floatValue + rhs.floatValue)
	}

	static func - (lhs: Float16, rhs: Float16) -> Float16 {
		return Float16(lhs.floatValue - rhs.floatValue)
	}

	static func * (lhs: Float16, rhs: Float16) -> Float16 {
		return Float16(lhs.floatValue * rhs.floatValue)
	}

	static func / (lhs: Float16, rhs: Float16) -> Float16 {
		return Float16(lhs.floatValue / rhs.floatValue)
	}
}
