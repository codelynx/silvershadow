//
//	RenderContext.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/12/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import Foundation
import MetalKit
import GLKit


//
//	RenderContext
//

struct RenderContext {
	let renderPassDescriptor: MTLRenderPassDescriptor
	let commandBuffer: MTLCommandBuffer
	let transform: GLKMatrix4
	let zoomScale: CGFloat

	var device: MTLDevice { return commandBuffer.device }

	func makeRenderCommandEncoder() -> MTLRenderCommandEncoder {
		return self.commandBuffer.makeRenderCommandEncoder(descriptor: self.renderPassDescriptor)
	}
}


extension RenderContext {

	/*
	func withCGContext(_ closure: ((CGContext)->())) {
		guard let mtkView = self.mtkView else { fatalError("no mtkView") }
		let bounds = mtkView.bounds
		#if os(iOS)
		let scale = mtkView.window?.screen.scale ?? 1
		#else
		let scale: CGFloat = 1
		#endif
		let (width, height, bytesPerRow) = (Int(bounds.width * scale), Int(bounds.height * scale), Int(bounds.width * scale) * 4)
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
		guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
					space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return }
		context.saveGState()
		context.setFillColor(XColor.clear.cgColor)
		context.fill(CGRect(0, 0, width, height))
		context.restoreGState()

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

		guard let cgImage = context.makeImage() else { fatalError("no cgImage") }
		if let imageTexture = self.device.texture(of: cgImage) {
			self.render(texture: imageTexture, in: CGRect(256, 256, 1024, 512))
		}
		
	}
	*/

}
