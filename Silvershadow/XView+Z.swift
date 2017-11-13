//
//	UIView+Z.swift
//	ZKit
//
//	Created by Kaz Yoshikawa on 12/12/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif


extension XView {

	func transform(to view: XView) -> CGAffineTransform {
		let targetRect = self.convert(self.bounds, to: view)
		return view.bounds.transform(to: targetRect)
	}

	func addSubviewToFit(_ view: XView) {
		view.frame = self.bounds
		self.addSubview(view)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
		view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
		view.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
		view.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
	}

	func setBorder(color: XColor?, width: CGFloat) {
        #if os(macOS)
        guard let layer = self.layer else { fatalError() }
        #endif

		layer.borderWidth = width
		layer.borderColor = color?.cgColor
	}

	#if os(macOS)
	var backgroundColor: NSColor? {
		get {
            return layer?.backgroundColor.flatMap { NSColor(cgColor: $0) }
		}
		set {
			self.wantsLayer = true // ??
			self.layer?.backgroundColor = newValue?.cgColor
		}
	}
	#endif

}
