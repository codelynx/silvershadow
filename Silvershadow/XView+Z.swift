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
		#if os(iOS)
		self.layer.borderWidth = width
		self.layer.borderColor = color?.cgColor
		#elseif os(macOS)
		self.layer?.borderWidth = width
		self.layer?.borderColor = color?.cgColor
		#endif
	}

	#if os(macOS)
	var backgroundColor: NSColor? {
		get {
			guard let backgroundColor = self.layer?.backgroundColor else { return nil }
			return NSColor(cgColor: backgroundColor)
		}
		set {
			self.wantsLayer = true // ??
			self.layer?.backgroundColor = newValue?.cgColor
		}
	}
	#endif
	
}
