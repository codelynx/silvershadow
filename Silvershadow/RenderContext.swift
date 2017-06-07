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
//	RenderContextState
//

struct RenderContextState {
	var renderPassDescriptor: MTLRenderPassDescriptor
	var commandQueue: MTLCommandQueue
	var contentSize: CGSize
	var deviceSize: CGSize // eg. MTKView's size, offscreen bitmap's size etc.
	var transform: GLKMatrix4
	var zoomScale: CGFloat
}

struct Stack<Element> {
    private var content : [Element]

    init() {
        content = []
    }

    mutating
    func push(_ element: Element) {
        content.append(element)
    }

    mutating
    func pop() -> Element? {
        guard let l = content.last else { return nil }
        defer {
            content.removeLast()
        }
        return l
    }
}
//
//	RenderContext
//

class RenderContext {
	var current: RenderContextState
	private var contextStack = Stack<RenderContextState>()

	var renderPassDescriptor: MTLRenderPassDescriptor {
		get { return current.renderPassDescriptor }
		set { current.renderPassDescriptor = newValue }
	}
	var commandQueue: MTLCommandQueue {
		get { return current.commandQueue }
		set { self.current.commandQueue = newValue }
	}
	var contentSize: CGSize {
		get { return current.contentSize }
		set { self.current.contentSize = newValue }
	}
	var deviceSize: CGSize { // eg. MTKView's size, offscreen bitmap's size etc.
		get { return current.deviceSize }
		set { self.deviceSize = newValue }
	}
	var transform: GLKMatrix4 {
		get { return current.transform }
		set { self.current.transform = newValue }
	}
	var zoomScale: CGFloat {
		get { return current.zoomScale }
		set {}
	}

	var device: MTLDevice { return commandQueue.device }

	//

	lazy var shadingTexture: MTLTexture = {
		let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .`default`,
					width: Int(self.deviceSize.width), height: Int(self.deviceSize.height), mipmapped: false)
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
		zoomScale: CGFloat = 1
	) {
		self.current = RenderContextState(
					renderPassDescriptor: renderPassDescriptor, commandQueue: commandQueue,
					contentSize: contentSize, deviceSize: deviceSize, transform: transform, zoomScale: zoomScale)
	}

	func makeCommandBuffer() -> MTLCommandBuffer {
		return commandQueue.makeCommandBuffer()
	}
	
	// MARK: -

	func pushContext() {
		let copiedState = self.current
		let copiedRenderpassDescriptor = self.current.renderPassDescriptor.copy() as! MTLRenderPassDescriptor
		self.current.renderPassDescriptor = copiedRenderpassDescriptor
		self.contextStack.push(copiedState)
	}
	
	func popContext() {
        guard let current = contextStack.pop() else { fatalError("cannot pop") }
        self.current = current
	}
}

extension RenderContext {

	func widthCGContext(_ closure: (CGContext) -> ()) {
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
