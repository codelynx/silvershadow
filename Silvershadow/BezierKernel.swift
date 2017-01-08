//
//  BezierKernel.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 1/7/17.
//  Copyright © 2017 Electricwoods LLC. All rights reserved.
//

import Foundation
import CoreGraphics
import MetalKit
import GLKit



class BezierKernel: Kernel {

	struct PathElement {
		var numberOfVertexes: Int32
		var vertexIndex: Int32;
		var p0: Point
		var p1: Point
		var p2: Point
		var p3: Point
	};

	var device: MTLDevice

	required init(device: MTLDevice) {
		self.device = device
	}
	
	lazy var computePipelineState: MTLComputePipelineState = {
		let library = self.device.newDefaultLibrary()!
		let computePipelineDescriptor = MTLComputePipelineDescriptor()
		computePipelineDescriptor.computeFunction = library.makeFunction(name: "compute_bezier_kernel")!
		let kernel = try! self.device.makeComputePipelineState(descriptor: computePipelineDescriptor, options: [], reflection: nil)
		return kernel
	}()

	func compute(_ commandQueue: MTLCommandQueue, _ cgPath: CGPath) -> MTLBuffer {
//		let commandQueue = self.device.makeCommandQueue()
		let commandBuffer = commandQueue.makeCommandBuffer()
	
		var vertexIndex: Int32 = 0
		var origin: Point?
		var point: Point?
		var elements = [PathElement]()
		let nan = Point(Float.nan, Float.nan)
		
		for pathElement in cgPath.pathElements {
			switch pathElement.type {
			case .moveToPoint:
				origin = Point(pathElement.points[0])
				point = origin
			case .addLineToPoint:
				guard let p0 = point else { continue }
				let p1 = Point(pathElement.points[0])
				let n = Int32((p1 - p0).length)
				elements.append(PathElement(numberOfVertexes: n, vertexIndex: vertexIndex, p0: p0, p1: p1, p2: nan, p3: nan))
				vertexIndex += n
				point = p1
			case .addQuadCurveToPoint:
				guard let p0 = point else { continue }
				let p1 = Point(pathElement.points[0])
				let p2 = Point(pathElement.points[1])
				let n = Int32((p1 - p0).length + (p2 - p1).length)
				elements.append(PathElement(numberOfVertexes: n, vertexIndex: vertexIndex, p0: p0, p1: p1, p2: p2, p3: nan))
				vertexIndex += n
				point = p2
				break
			case .addCurveToPoint:
				guard let p0 = point else { continue }
				let p1 = Point(pathElement.points[0])
				let p2 = Point(pathElement.points[1])
				let p3 = Point(pathElement.points[2])
				let n = Int32((p1 - p0).length + (p2 - p1).length + (p3 - p2).length)
				elements.append(PathElement(numberOfVertexes: n, vertexIndex: vertexIndex, p0: p0, p1: p1, p2: p2, p3: p3))
				vertexIndex += n
				point = p3
				break
			case .closeSubpath:
				guard let p0 = point else { continue }
				guard let p1 = origin else { continue }
				let n = Int32((p1 - p0).length)
				elements.append(PathElement(numberOfVertexes: n, vertexIndex: vertexIndex, p0: p0, p1: p1, p2: nan, p3: nan))
				vertexIndex += n
				point = nil
				origin = nil
			break
			}
		}
		
		let vertexBufferLength = MemoryLayout<PointVertex>.stride * Int(vertexIndex)
		let vertexBuffer = self.device.makeBuffer(length: vertexBufferLength, options: [.storageModeShared]) // todo:
		

		let elementBufferLength = MemoryLayout<PathElement>.size * Int(elements.count)
		let elementBuffer = self.device.makeBuffer(bytes: elements, length: elementBufferLength, options: MTLResourceOptions())
	
		let encoder = commandBuffer.makeComputeCommandEncoder()
		encoder.setComputePipelineState(self.computePipelineState)
		encoder.setBuffer(elementBuffer, offset: 0, at: 0)
		encoder.setBuffer(vertexBuffer, offset: 0, at: 1)

		let threadWidth = self.computePipelineState.threadExecutionWidth
		let threadPerGroup = MTLSize(width: 4, height: 1, depth: 1)
		let numberOfThredgroups = MTLSize(width: Int(ceil(Float(elements.count) / Float(threadWidth))), height: 1, depth: 1)

		encoder.dispatchThreadgroups(threadPerGroup, threadsPerThreadgroup: numberOfThredgroups)
		encoder.endEncoding()
		
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()

		let vertexArray = UnsafeMutablePointer<PointVertex>(OpaquePointer(vertexBuffer.contents()))
		for index in 0 ..< vertexIndex {
			let vertex = vertexArray[Int(index)]
			print("x=\(vertex.x), y=\(vertex.y), w=\(vertex.width)")
		}
		return vertexBuffer
	}

}
