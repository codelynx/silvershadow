//
//  RenderCanvasContext.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 2/19/17.
//  Copyright © 2017 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


class RenderCanvasContext: RenderContext {

	var bounds: Rect
	var shadingTexture: MTLTexture
	var brushShape: MTLTexture
	var brushPattern: MTLTexture

	init(
		renderPassDescriptor: MTLRenderPassDescriptor,
		commandBuffer: MTLCommandBuffer,
		transform: GLKMatrix4,
		zoomScale: CGFloat,
		bounds: CGRect,
		shadingTexture: MTLTexture,
		brushShape: MTLTexture,
		brushPattern: MTLTexture
	) {
		self.bounds = Rect(bounds)
		self.shadingTexture = shadingTexture
		self.brushShape = brushShape
		self.brushPattern = brushPattern
		super.init(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer, transform: transform, zoomScale: zoomScale)
	}

}
