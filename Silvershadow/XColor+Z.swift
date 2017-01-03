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
		let color = CIColor(cgColor: self.cgColor)
		return (color.red, color.green, color.blue, color.alpha)
	}

}


