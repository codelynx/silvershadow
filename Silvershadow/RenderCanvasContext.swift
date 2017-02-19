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

	var shadingTexture: MTLTexture

	init(
		renderPassDescriptor: MTLRenderPassDescriptor,
		commandBuffer: MTLCommandBuffer,
		transform: GLKMatrix4,
		zoomScale: CGFloat,
		shadingTexture: MTLTexture
	) {
		self.shadingTexture = shadingTexture
		super.init(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer, transform: transform, zoomScale: zoomScale)
	}

}
