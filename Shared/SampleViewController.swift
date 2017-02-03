//
//	ViewController.swift
//	SilvershadowApp_mac
//
//	Created by Kaz Yoshikawa on 12/25/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif


class SampleViewController: XViewController {

	var sampleScene: SampleScene!
	var sampleCanvas: SampleCanvas!

	@IBOutlet var renderView: RenderView!

	override func viewDidLoad() {
		super.viewDidLoad()

		let device = self.renderView.device
		let contentSize = CGSize(2048, 1024)

		// either one can be uncommented not both

//		self.sampleScene = SampleScene(device: device, contentSize: contentSize)
//		self.renderView.scene = self.sampleScene

		self.sampleCanvas = SampleCanvas(device: device, contentSize: contentSize)
		self.renderView.scene = self.sampleCanvas
	}

	#if os(macOS)
	override var representedObject: Any? {
		didSet {
		}
	}
	#endif

}

