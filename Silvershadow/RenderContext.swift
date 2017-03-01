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
	let commandQueue: MTLCommandQueue
	let contentSize: CGSize
	let deviceSize: CGSize // eg. MTKView's size, offscreen bitmap's size etc.
	let transform: GLKMatrix4
	let zoomScale: CGFloat

	var device: MTLDevice { return commandQueue.device }

	//

	lazy var shadingTexture: MTLTexture = {
		let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: defaultPixelFormat,
					width: Int(self.contentSize.width), height: Int(self.contentSize.height), mipmapped: false)
		descriptor.usage = [.shaderRead, .renderTarget]
		return self.device.makeTexture(descriptor: descriptor)
	}()

	lazy var brushShape: MTLTexture = {
		return self.device.texture(of: XImage(named: "Particle")!)!
	}()

	lazy var brushPattern: MTLTexture = {
		return self.device.texture(of: XImage(named: "Pencil")!)!
	}()

	init(
		renderPassDescriptor: MTLRenderPassDescriptor,
		commandQueue: MTLCommandQueue,
		contentSize: CGSize,
		deviceSize: CGSize,
		transform: GLKMatrix4,
		zoomScale: CGFloat
	) {
		self.renderPassDescriptor = renderPassDescriptor
		self.commandQueue = commandQueue
		self.contentSize = contentSize
		self.deviceSize = deviceSize
		self.transform = transform
		self.zoomScale = zoomScale
	}

	func makeCommandBuffer() -> MTLCommandBuffer {
		return self.commandQueue.makeCommandBuffer()
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
