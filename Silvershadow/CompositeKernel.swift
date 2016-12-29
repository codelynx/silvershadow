//
//  CompositeRenderer.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 12/30/16.
//  Copyright © 2016 Electricwoods LLC. All rights reserved.
//


import Foundation
import MetalKit
import GLKit


class CompositeKernel: Kernel {

	var device: MTLDevice

	required init(device: MTLDevice) {
		self.device = device
	}
	
	lazy var computePipelineState: MTLComputePipelineState = {
		let library = self.device.newDefaultLibrary()!
		let computePipelineDescriptor = MTLComputePipelineDescriptor()
		computePipelineDescriptor.computeFunction = library.makeFunction(name: "composite_kernel")!
		let kernel = try! self.device.makeComputePipelineState(descriptor: computePipelineDescriptor, options: [], reflection: nil)
		return kernel
	}()

	func compute(_ commandBuffer: MTLCommandBuffer, _ source: MTLTexture, _ destination: MTLTexture) {
		assert(source.width == destination.width && source.height == destination.height)
		assert(source.usage.contains(.shaderRead))
		assert(destination.usage.contains(.shaderRead) && destination.usage.contains(.shaderWrite))
		let compositeEncoder = commandBuffer.makeComputeCommandEncoder()
		compositeEncoder.setComputePipelineState(self.computePipelineState)
		compositeEncoder.setTexture(source, at: 0)
		compositeEncoder.setTexture(destination, at: 1)
		compositeEncoder.dispatchThreadgroups(self.threadSize(source), threadsPerThreadgroup: self.threadsPerThreadgroup(source))
		compositeEncoder.endEncoding()
	}

	func threadSize(_ texture: MTLTexture) -> MTLSize {
		// must be <= 1024. (device threadgroup size limit)
		var size = 32
		while (texture.width / size) * (texture.height / size) > 1024 {
			size *= 2
		}
		return MTLSize(width: size, height: size, depth: 1)
	}
	
	func threadsPerThreadgroup(_ texture: MTLTexture) -> MTLSize {
		let threadSize = self.threadSize(texture)
		return MTLSize(width: texture.width / threadSize.width, height: texture.height / threadSize.height, depth: 1)
	}

}
