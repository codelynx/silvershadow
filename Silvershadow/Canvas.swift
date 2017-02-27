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

	fileprivate (set) var canvasLayers: [CanvasLayer]
	
	var overlayCanvasLayer: CanvasLayer? {
		didSet {
			overlayCanvasLayer?.canvas = self
			self.setNeedsDisplay()
		}
	}

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

	lazy var shadingTexture: MTLTexture = {
		let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: defaultPixelFormat,
					width: Int(self.contentSize.width), height: Int(self.contentSize.height), mipmapped: self.mipmapped)
		descriptor.usage = [.shaderRead, .renderTarget]
		return self.device.makeTexture(descriptor: descriptor)
	}()

	lazy var subcomandQueue: MTLCommandQueue = {
		return self.device.makeCommandQueue()
	}()

	override func update() {
		print("\(#function)")
		let commandQueue = self.subcomandQueue
		let canvasTexture = self.canvasTexture

		let backgroundColor = XColor(rgba: self.backgroundColor.rgba)
		let rgba = backgroundColor.rgba
		let (r, g, b, a) = (Double(rgba.r), Double(rgba.g), Double(rgba.b), Double(rgba.a))
		
		//
		let renderPassDescriptor = MTLRenderPassDescriptor()
		renderPassDescriptor.colorAttachments[0].texture = canvasTexture
		renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(r, g, b, a)
		renderPassDescriptor.colorAttachments[0].storeAction = .store

		renderPassDescriptor.colorAttachments[0].loadAction = .load
		let subtransform = GLKMatrix4(self.transform)

		// build an image per layer then flatten that image to the canvas texture
		let subtexture = self.sublayerTexture

		let subrenderPassDescriptor = MTLRenderPassDescriptor()
		subrenderPassDescriptor.colorAttachments[0].texture = subtexture
		subrenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
		subrenderPassDescriptor.colorAttachments[0].loadAction = .clear
		subrenderPassDescriptor.colorAttachments[0].storeAction = .store

		let commandBuffer = commandQueue.makeCommandBuffer()

		for canvasLayer in self.canvasLayers {

			if canvasLayer.isHidden { continue }

			// render a layer

			let subrenderContext = RenderCanvasContext(
						renderPassDescriptor: subrenderPassDescriptor,
						commandQueue: commandQueue, transform: subtransform, zoomScale: 1, bounds: self.bounds,
						shadingTexture: self.shadingTexture)
			canvasLayer.render(context: subrenderContext)


			// flatten image

			let transform = GLKMatrix4Identity
			let renderContext = RenderContext(renderPassDescriptor: renderPassDescriptor,
							commandQueue: commandQueue, transform: transform, zoomScale: 1)
			renderContext.render(texture: subtexture, in: Rect(-1, -1, 2, 2))

		}

		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()

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

		// build rendering overlay canvas layer

		//let commandBuffer = context.makeCommandBuffer()

		guard let overlayCanvasLayer = self.overlayCanvasLayer else { return }
		print("render: \(overlayCanvasLayer.name)")
		let subtexture = self.sublayerTexture
		let subtransform = GLKMatrix4(self.transform)

		let subrenderPassDescriptor = MTLRenderPassDescriptor()
		subrenderPassDescriptor.colorAttachments[0].texture = subtexture
		subrenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
		subrenderPassDescriptor.colorAttachments[0].loadAction = .clear
		subrenderPassDescriptor.colorAttachments[0].storeAction = .store

		let subrenderContext = RenderCanvasContext(renderPassDescriptor: subrenderPassDescriptor,
					commandQueue: context.commandQueue, transform: subtransform, zoomScale: 1, bounds: self.bounds,
					shadingTexture: self.shadingTexture)
		overlayCanvasLayer.render(context: subrenderContext)

		// render canvas texture

		self.canvasRenderer.renderImage(context: context, texture: self.canvasTexture, in: Rect(self.bounds))

		// render overlay canvas layer
		
		context.render(texture: subtexture, in: Rect(self.bounds))
		
	}

	func addLayer(_ layer: CanvasLayer) {
		self.canvasLayers.append(layer)
		layer.didMoveTo(canvas: self)
		self.setNeedsUpdate()
	}

	func bringLayer(toFront: CanvasLayer) {
		assert(false, "not yet")
	}
	
	func sendLayer(toBack: CanvasLayer) {
		assert(false, "not yet")
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

