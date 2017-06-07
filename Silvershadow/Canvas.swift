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

extension MTLTextureDescriptor {
    static func texture2DDescriptor(size: CGSize, mipmapped: Bool, usage: MTLTextureUsage = []) -> MTLTextureDescriptor {
        let desc = texture2DDescriptor(pixelFormat: .`default`,
                                       width: Int(size.width),
                                       height: Int(size.height),
                                       mipmapped: mipmapped)
        desc.usage = usage
        return desc
    }
}

extension MTLDevice {
    final func makeTexture2D(size: CGSize, mipmapped: Bool, usage: MTLTextureUsage) -> MTLTexture {
        return makeTexture(descriptor: .texture2DDescriptor(size: size,
                                                            mipmapped: mipmapped,
                                                            usage: usage))
    }
}

class Canvas: Scene {

    // master texture of canvas
    lazy var canvasTexture: MTLTexture = {
        return self.device.makeTexture2D(size: self.contentSize,
                                         mipmapped: self.mipmapped,
                                         usage: [.shaderRead, .shaderWrite, .renderTarget])
    }()

    lazy var canvasRenderer: ImageRenderer = {
        return self.device.renderer()
    }()

    fileprivate (set) var canvasLayers: [CanvasLayer]

    var overlayCanvasLayer: CanvasLayer? {
        didSet {
            overlayCanvasLayer?.canvas = self
            setNeedsDisplay()
        }
    }

    override init?(device: MTLDevice, contentSize: CGSize) {
        canvasLayers = []
        super.init(device: device, contentSize: contentSize)
    }

    override func didMove(to renderView: RenderView) {
        super.didMove(to: renderView)
    }

    lazy var sublayerTexture: MTLTexture = {
        return self.device.makeTexture2D(size: self.contentSize,
                                         mipmapped: self.mipmapped,
                                         usage: [.shaderRead, .renderTarget])
    }()

    lazy var subcomandQueue: MTLCommandQueue = {
        return self.device.makeCommandQueue()
    }()

    override func update() {

        let date = Date()
        defer { Swift.print("Canvas: update", -date.timeIntervalSinceNow * 1000, " ms") }

        let commandQueue = subcomandQueue
        let canvasTexture = self.canvasTexture

        //		let backgroundColor = XColor(rgba: self.backgroundColor.rgba)
        //		let rgba = backgroundColor.rgba
        let (r, g, b, a) = (Double(1), Double(0), Double(0), Double(0))

        //
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = canvasTexture
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(r, g, b, a)
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        // clear canvas texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        renderPassDescriptor.colorAttachments[0].loadAction = .load


        // build an image per layer then flatten that image to the canvas texture
        let subtexture = self.sublayerTexture
        let subtransform = GLKMatrix4(transform)

        let subrenderPassDescriptor = MTLRenderPassDescriptor()
        subrenderPassDescriptor.colorAttachments[0].texture = subtexture
        subrenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor()
        subrenderPassDescriptor.colorAttachments[0].storeAction = .store


        for canvasLayer in canvasLayers where !canvasLayer.isHidden {

            // clear subtexture

            subrenderPassDescriptor.colorAttachments[0].loadAction = .clear
            let commandBuffer = commandQueue.makeCommandBuffer()
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: subrenderPassDescriptor)
            commandEncoder.endEncoding()
            commandBuffer.commit()
            subrenderPassDescriptor.colorAttachments[0].loadAction = .load

            let subrenderContext = RenderContext(renderPassDescriptor: subrenderPassDescriptor,
                                                 commandQueue: commandQueue,
                                                 contentSize: contentSize,
                                                 deviceSize: contentSize,
                                                 transform: subtransform)

            // render a layer
            canvasLayer.render(context: subrenderContext)

            // flatten image
            let renderContext = RenderContext(renderPassDescriptor: renderPassDescriptor,
                                              commandQueue: commandQueue,
                                              contentSize: contentSize,
                                              deviceSize: contentSize,
                                              transform: .identity)
            renderContext.render(texture: subtexture, in: Rect(-1, -1, 2, 2))

        }


        //		let commandBuffer = commandQueue.makeCommandBuffer()
        //		commandBuffer.commit()
        //		commandBuffer.waitUntilCompleted()

        // drawing in offscreen (canvasTexture) is done,
        setNeedsDisplay()
    }

    var threadSize: MTLSize {
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

        let date = Date()
        defer { Swift.print("Canvas: render", -date.timeIntervalSinceNow * 1000, " ms") }

        // build rendering overlay canvas layer

        //let commandBuffer = context.makeCommandBuffer()

        guard let overlayCanvasLayer = overlayCanvasLayer else { return }
        print("render: \(Date()), \(String(describing: overlayCanvasLayer.name))")

        let subtexture = self.sublayerTexture
        let subtransform = GLKMatrix4(transform)

        let subrenderPassDescriptor = MTLRenderPassDescriptor()
        subrenderPassDescriptor.colorAttachments[0].texture = subtexture
        subrenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor()
        subrenderPassDescriptor.colorAttachments[0].loadAction = .clear
        subrenderPassDescriptor.colorAttachments[0].storeAction = .store

        // clear subtexture
        let commandBuffer = context.makeCommandBuffer()
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: subrenderPassDescriptor)
        commandEncoder.endEncoding()
        commandBuffer.commit()

        subrenderPassDescriptor.colorAttachments[0].loadAction = .load
        let subrenderContext = RenderContext(renderPassDescriptor: subrenderPassDescriptor,
                                             commandQueue: context.commandQueue,
                                             contentSize: contentSize,
                                             deviceSize: contentSize,
                                             transform: subtransform,
                                             zoomScale: 1)
        overlayCanvasLayer.render(context: subrenderContext)

        // render canvas texture

        canvasRenderer.renderTexture(context: context, texture: canvasTexture, in: Rect(bounds))

        // render overlay canvas layer

        context.render(texture: subtexture, in: Rect(bounds))
    }

    func addLayer(_ layer: CanvasLayer) {
        canvasLayers.append(layer)
        layer.didMoveTo(canvas: self)
        setNeedsUpdate()
    }

    func bringLayer(toFront: CanvasLayer) {
        assert(false, "not yet")
    }

    func sendLayer(toBack: CanvasLayer) {
        assert(false, "not yet")
    }

}

extension RangeReplaceableCollection where Iterator.Element : Equatable {
    mutating func remove(_ element: Iterator.Element) -> Index? {
        return index(of: element).map { self.remove(at: $0); return $0 }
    }
}

extension CanvasLayer {
    func removeFromCanvas() {
        _ = canvas?.canvasLayers.remove(self)
    }
}

