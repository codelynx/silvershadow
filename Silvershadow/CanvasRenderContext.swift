//
//  CanvasRenderContext.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 1/16/17.
//  Copyright © 2017 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


class CanvasRenderContext: RenderContext {
	
	var masking: MTLTexture
	var brushUniformBuffer: MTLBuffer
	
	init(	renderPassDescriptor: MTLRenderPassDescriptor,
			commandBuffer: MTLCommandBuffer,
			contentSize: CGSize,
			transform: GLKMatrix4,
			zoomScale: CGFloat,
			masking: MTLTexture,
			brushUniformBuffer: MTLBuffer
	) {
		self.masking = masking
		self.brushUniformBuffer = brushUniformBuffer
		super.init(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer, contentSize: contentSize, transform: transform, zoomScale: zoomScale)
	}

}
