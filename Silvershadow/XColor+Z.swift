//
//	UIColor+Z.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 12/18/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif


extension XColor {

	var rgba: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
		var r: CGFloat = 0
		var g: CGFloat = 0
		var b: CGFloat = 0
		var a: CGFloat = 0
		self.getRed(&r, green: &g, blue: &b, alpha: &a)
		return (r, g, b, a)
	}

}




