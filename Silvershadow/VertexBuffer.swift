//
//	VertexBuffer.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 1/11/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit

//
//	VertexBuffer
//

class VertexBuffer<T> {

	let device: MTLDevice
	var buffer: MTLBuffer
	var count: Int
	var capacity: Int

	init(device: MTLDevice, vertices: [T], capacity: Int? = nil) {
		assert(vertices.count <= capacity ?? vertices.count)
		self.device = device
		self.count = vertices.count
		let capacity = capacity ?? vertices.count
		let length = MemoryLayout<T>.stride * capacity
		self.capacity = capacity
		self.buffer = device.makeBuffer(bytes: vertices, length: length, options: [.storageModeShared]) // !?!
	}

	deinit {
//		buffer.setPurgeableState(.empty)
	}

	func append(_ vertices: [T]) {
		if self.count + vertices.count < self.capacity {
			let vertexArray = UnsafeMutablePointer<T>(OpaquePointer(self.buffer.contents()))
			for index in 0 ..< vertices.count {
				vertexArray[self.count + index] = vertices[index]
			}
			self.count += vertices.count
		}
		else {
			let count = self.count
			let length = MemoryLayout<T>.stride * (count + vertices.count)
			let buffer = self.device.makeBuffer(length: length, options: [.storageModeShared])
			let sourceArrayPtr = UnsafeMutablePointer<T>(OpaquePointer(self.buffer.contents()))
			let sourceArray = UnsafeMutableBufferPointer<T>(start: sourceArrayPtr, count: count)
			let destinationArrayPtr = UnsafeMutablePointer<T>(OpaquePointer(buffer.contents()))
			let destinationArray = UnsafeMutableBufferPointer<T>(start: destinationArrayPtr, count: count + vertices.count)

			(0 ..< count).forEach { destinationArray[$0] = sourceArray[$0] }
			(0 ..< vertices.count).forEach { destinationArray[count + $0] = vertices[$0] }

			self.count = count + vertices.count
			self.capacity = self.count

			self.buffer = buffer
		}
	}

	func set(_ vertices: [T]) {
		if vertices.count < self.capacity {
			let destinationArrayPtr = UnsafeMutablePointer<T>(OpaquePointer(buffer.contents()))
			let destinationArray = UnsafeMutableBufferPointer<T>(start: destinationArrayPtr, count: count + vertices.count)
			(0 ..< vertices.count).forEach { destinationArray[$0] = vertices[$0]  }
			self.count = vertices.count
		}
		else {
			let bytes = MemoryLayout<T>.size * vertices.count
			let buffer = device.makeBuffer(bytes: vertices, length: bytes, options: [.storageModeShared])
			self.count = vertices.count
			self.capacity = vertices.count
			self.buffer = buffer
		}
	}

	var vertices: [T] {
		let vertexArray = UnsafeMutablePointer<T>(OpaquePointer(self.buffer.contents()))
		return (0 ..< count).map { vertexArray[$0] }
	}

}

