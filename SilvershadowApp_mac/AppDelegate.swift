//
//	AppDelegate.swift
//	SilvershadowApp_mac
//
//	Created by Kaz Yoshikawa on 12/25/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var sampleSceneMenuItem: NSMenuItem!
	@IBOutlet weak var sampleCanvasMenuItem: NSMenuItem!

	func applicationDidFinishLaunching(_ aNotification: Notification) {

		let app = NSApplication.shared
		if let sampleSceneAction = sampleCanvasMenuItem.action {
			app.sendAction(sampleSceneAction, to: app, from: sampleCanvasMenuItem)
		}

	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}

