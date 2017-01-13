//
//	Canvas.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/28/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif


//	Canvas
//
//	Canvas is designed for rendering on offscreen bitmap target.  Whereas, Scene is for rendering
//	on screen (MTKView) directly.  Beaware of content size affects big impact to the memory usage.
//

class Canvas: Scene {

	// master texture of canvas
	lazy var canvasTexture: MTLTexture = {
		let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: defaultPixelFormat,
					width: Int(self.contentSize.width), height: Int(self.contentSize.height), mipmapped: self.mipmapped)
		descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
		return self.device.makeTexture(descriptor: descriptor)
	}()

	lazy var canvasRenderer: ImageRenderer = {
		return self.device.renderer()
	}()

	lazy var canvasVertexes: VertexBuffer<ImageVertex>? = {
		let size = Size(Float(self.contentSize.width), Float(self.contentSize.height))
		return self.canvasRenderer.vertexBuffer(for: Rect(0, 0, size.width, size.height))
	}()

	fileprivate (set) var canvasLayers: [CanvasLayer]

	override init?(device: MTLDevice, contentSize: CGSize) {
		self.canvasLayers = [CanvasLayer]()
		super.init(device: device, contentSize: contentSize)
	}

	override func didMove(to renderView: RenderView) {
		super.didMove(to: renderView)
	}

	lazy var sublayerTexture: MTLTexture = {
		let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: defaultPixelFormat,
					width: Int(self.contentSize.width), height: Int(self.contentSize.height), mipmapped: self.mipmapped)
		descriptor.usage = [.shaderRead, .renderTarget]
		return self.device.makeTexture(descriptor: descriptor)
	}()

	var subcomandQueue: MTLCommandQueue {
		return super.commandQueue!
	}

	override func update() {
		let commandQueue = self.subcomandQueue
		let canvasTexture = self.canvasTexture

		let backgroundColor = XColor(ciColor: self.backgroundColor.ciColor)
		let rgba = backgroundColor.rgba
		let (r, g, b, a) = (Double(rgba.r), Double(rgba.g), Double(rgba.b), Double(rgba.a))
		
		//
		let renderPassDescriptor = MTLRenderPassDescriptor()
		renderPassDescriptor.colorAttachments[0].texture = canvasTexture
		renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(r, g, b, a)
		renderPassDescriptor.colorAttachments[0].storeAction = .store

		// clear the canvas texture
		let commandBuffer = commandQueue.makeCommandBuffer()
		renderPassDescriptor.colorAttachments[0].loadAction = .clear
		let clearEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
		clearEncoder.endEncoding()
		commandBuffer.commit()

		renderPassDescriptor.colorAttachments[0].loadAction = .load
		let subtransform = GLKMatrix4(self.transform)

		// build an image per layer then flatten that image to the canvas texture
		let subtexture = self.sublayerTexture

		for canvasLayer in self.canvasLayers {

			let subcommandBuffer = commandQueue.makeCommandBuffer()
			guard !canvasLayer.isHidden else { continue }

			let subrenderPassDescriptor = MTLRenderPassDescriptor()
			subrenderPassDescriptor.colorAttachments[0].texture = subtexture
			subrenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
			subrenderPassDescriptor.colorAttachments[0].storeAction = .store

			// clear the subtexture
			subrenderPassDescriptor.colorAttachments[0].loadAction = .clear
			let clearEncoder = subcommandBuffer.makeRenderCommandEncoder(descriptor: subrenderPassDescriptor)
			clearEncoder.endEncoding()

			subrenderPassDescriptor.colorAttachments[0].loadAction = .load
			let subrenderContext = RenderContext(renderPassDescriptor: subrenderPassDescriptor,
						commandBuffer: subcommandBuffer, contentSize: self.contentSize, transform: subtransform, zoomScale: 1)
			canvasLayer.render(context: subrenderContext)

			subcommandBuffer.commit()
			subcommandBuffer.waitUntilCompleted()

			let commandBuffer = commandQueue.makeCommandBuffer()

			let transform = GLKMatrix4Identity
			let renderContext = RenderContext(renderPassDescriptor: renderPassDescriptor,
							commandBuffer: commandBuffer, contentSize: self.contentSize, transform: transform, zoomScale: 1)
			renderContext.render(texture: subtexture, in: Rect(-1, -1, 2, 2))

			commandBuffer.commit()
			commandBuffer.waitUntilCompleted()

		}

		// drawing in offscreen (canvasTexture) is done,
		self.setNeedsDisplay()
	}
	
	var threadSize: MTLSize {
		// must be <= 1024. (device threadgroup size limit)
		var size = 32
		while (canvasTexture.width / size) * (canvasTexture.height / size) > 1024 {
			size *= 2
		}
		return MTLSize(width: size, height: size, depth: 1)
	}
	
	var threadsPerThreadgroup: MTLSize {
		let threadSize = self.threadSize
		return MTLSize(width: canvasTexture.width / threadSize.width, height: canvasTexture.height / threadSize.height, depth: 1)
	}

	override func render(in context: RenderContext) {
		if let canvasVertexes = self.canvasVertexes {
			self.canvasRenderer.renderImage(context: context, texture: self.canvasTexture, vertexBuffer: canvasVertexes)
		}
	}

	func addLayer(_ layer: CanvasLayer) {
		self.canvasLayers.append(layer)
		layer.didMoveTo(canvas: self)
		self.setNeedsUpdate()
	}

	func bringLayer(toFront: CanvasLayer) {
	}
	
	func sendLayer(toBack: CanvasLayer) {
	}

}

extension CanvasLayer {

	func removeFromCanvas() {
		if let canvas = self.canvas {
			if let index = canvas.canvasLayers.index(of: self) {
				canvas.canvasLayers.remove(at: index)
			}
		}
	}

}

