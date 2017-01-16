//
//	RenderContext.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/12/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


//
//	RenderContext
//

class RenderContext {
	let renderPassDescriptor: MTLRenderPassDescriptor
	let commandBuffer: MTLCommandBuffer
	let contentSize: CGSize
	let transform: GLKMatrix4
	let zoomScale: CGFloat

	var device: MTLDevice { return commandBuffer.device }

	init(
		renderPassDescriptor: MTLRenderPassDescriptor,
		commandBuffer: MTLCommandBuffer,
		contentSize: CGSize,
		transform: GLKMatrix4,
		zoomScale: CGFloat
		
	) {
		self.renderPassDescriptor = renderPassDescriptor
		self.commandBuffer = commandBuffer
		self.contentSize = contentSize
		self.transform = transform
		self.zoomScale = zoomScale
	}

	func makeCommandBuffer() -> MTLCommandBuffer {
		return self.commandBuffer.commandQueue.makeCommandBuffer()
	}

	func makeRenderCommandEncoder() -> MTLRenderCommandEncoder {
		return self.commandBuffer.makeRenderCommandEncoder(descriptor: self.renderPassDescriptor)
	}
}

extension RenderContext {

	func widthCGContext(contentSize: CGSize, _ closure: ((CGContext)->())) {
		let (width, height, bytesPerRow) = (Int(contentSize.width), Int(contentSize.height), Int(contentSize.width) * 4)
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
		guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
					space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return }
		context.clear(CGRect(0, 0, width, height))

		let transform = CGAffineTransform.identity
					.translatedBy(x: 0, y: contentSize.height)
					.scaledBy(x: 1, y: -1)
		context.concatenate(transform)
		context.saveGState()
 
		#if os(iOS)
		UIGraphicsPushContext(context)
		#elseif os(macOS)
		let savedContext = NSGraphicsContext.current()
		let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
		NSGraphicsContext.setCurrent(graphicsContext)
		#endif

		closure(context)

		#if os(iOS)
		UIGraphicsPopContext()
		#elseif os(macOS)
		NSGraphicsContext.setCurrent(savedContext)
		#endif

		context.restoreGState()
		guard let cgImage = context.makeImage() else { fatalError("failed creating cgImage") }
		guard let texture = self.device.texture(of: cgImage) else { fatalError("failed creating texture") }
		self.render(texture: texture, in: Rect(0, 0, width, height))
	}

}
