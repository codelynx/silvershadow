//
//	VertexBuffer.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 1/11/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


#if os(iOS)
typealias XHeap = MTLHeap
#elseif os(macOS)
typealias XHeap = MTLDevice
#endif


//
//	VertexBuffer
//

class MetalBuffer<T> {

	let heap: XHeap
	var buffer: MTLBuffer
	var count: Int
	var capacity: Int

	init(heap: XHeap, vertices: [T]? = nil, capacity: Int? = nil) {
		self.heap = heap
		let count = vertices?.count ?? 0
		let capacity = capacity ?? count
		assert(capacity > 0)
		let length = MemoryLayout<T>.stride * capacity
		self.count = count
		self.capacity = capacity
		let buffer = self.heap.makeBuffer(length: length, options: [.storageModeShared])
		if let vertices = vertices {
			let destinationArrayPtr = UnsafeMutablePointer<T>(OpaquePointer(buffer.contents()))
			let destinationArray = UnsafeMutableBufferPointer<T>(start: destinationArrayPtr, count: vertices.count)
			(0 ..< vertices.count).forEach { destinationArray[$0] = vertices[$0]  }
		}
		self.buffer = buffer
	}

	deinit {
//		buffer.setPurgeableState(.empty)
	}

	func append(_ items: [T]) {
		assert(buffer.storageMode == .shared)
		if self.count + items.count < self.capacity {
			let vertexArray = UnsafeMutablePointer<T>(OpaquePointer(self.buffer.contents()))
			for index in 0 ..< items.count {
				vertexArray[self.count + index] = items[index]
			}
			self.count += items.count
		}
		else {
			let count = self.count
			let length = MemoryLayout<T>.stride * (count + items.count)
			let buffer = self.heap.makeBuffer(length: length, options: [.storageModeShared])
			let sourceArrayPtr = UnsafeMutablePointer<T>(OpaquePointer(self.buffer.contents()))
			let sourceArray = UnsafeMutableBufferPointer<T>(start: sourceArrayPtr, count: count)
			let destinationArrayPtr = UnsafeMutablePointer<T>(OpaquePointer(buffer.contents()))
			let destinationArray = UnsafeMutableBufferPointer<T>(start: destinationArrayPtr, count: count + items.count)

			(0 ..< count).forEach { destinationArray[$0] = sourceArray[$0] }
			(0 ..< items.count).forEach { destinationArray[count + $0] = items[$0] }

			self.count = count + items.count
			self.capacity = self.count

			self.buffer = buffer
		}
	}

	func set(_ items: [T]) {
		assert(buffer.storageMode == .shared)
		if items.count < self.capacity {
			let destinationArrayPtr = UnsafeMutablePointer<T>(OpaquePointer(buffer.contents()))
			let destinationArray = UnsafeMutableBufferPointer<T>(start: destinationArrayPtr, count: count + items.count)
			(0 ..< items.count).forEach { destinationArray[$0] = items[$0]  }
			self.count = items.count
		}
		else {
			let bytes = MemoryLayout<T>.size * items.count
			let buffer = self.heap.makeBuffer(bytes: items, length: bytes, options: [.storageModeShared])
			self.count = items.count
			self.capacity = items.count
			self.buffer = buffer
		}
	}

	var items: [T] {
		let vertexArray = UnsafeMutablePointer<T>(OpaquePointer(self.buffer.contents()))
		return (0 ..< count).map { vertexArray[$0] }
	}

	subscript(index: Int) -> T {
		get {
			assert(buffer.storageMode == .shared)
			guard index < self.count else { fatalError("Buffer Overrun") }
			let itemsArray = UnsafeMutablePointer<T>(OpaquePointer(self.buffer.contents()))
			return itemsArray[index]
		}
		set {
			assert(buffer.storageMode == .shared)
			guard index < self.count else { fatalError("Buffer Overrun") }
			let itemsArray = UnsafeMutablePointer<T>(OpaquePointer(self.buffer.contents()))
			itemsArray[index] = newValue
		}
	}

	var item: T {
		get { return self[0] }
		set { self[0] = newValue }
	}

}

