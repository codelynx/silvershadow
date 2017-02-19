//
//  StencilRenderer.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 1/4/17.
//  Copyright © 2017 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


class StencilRenderer: Renderer {

	let device: MTLDevice

	required init(device: MTLDevice) {
		self.device = device
	}


}
