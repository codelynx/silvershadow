//
//	ViewController.swift
//	SilvershadowApp
//
//	Created by Kaz Yoshikawa on 12/25/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif


class SampleSceneViewController: XViewController {

	var sampleScene: SampleScene!

	@IBOutlet var renderView: RenderView!

	override func viewDidLoad() {
		super.viewDidLoad()

		let device = self.renderView.device
		let contentSize = CGSize(2048, 1024)

		self.sampleScene = SampleScene(device: device, contentSize: contentSize)
		self.renderView.scene = self.sampleScene
	}

	#if os(macOS)
	override var representedObject: Any? {
		didSet {
		}
	}
	#endif

}

