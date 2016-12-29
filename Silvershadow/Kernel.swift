//
//  Kernel.swift
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 12/30/16.
//  Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import MetalKit
import GLKit


protocol Kernel: class {
	var device: MTLDevice { get }
	init(device: MTLDevice)
}


extension Kernel {
	var library: MTLLibrary {
		return self.device.newDefaultLibrary()!
	}
}


class KernelRegistry {
	private var registory = [String: Kernel]()
	subscript(key: String) -> Kernel? {
		get { return registory[key] }
		set { registory[key] = newValue }
	}
}


fileprivate var deviceKernelMap = NSMapTable<MTLDevice, KernelRegistry>.weakToStrongObjects()


extension MTLDevice {

	func kernel<T: Kernel>() -> T {
		let key = NSStringFromClass(T.self)
		let registry = deviceKernelMap.object(forKey: self) ?? KernelRegistry()
		let renderer = registry[key] ?? T(device: self)
		registry[key] = renderer
		deviceKernelMap.setObject(registry, forKey: self)
		return renderer as! T
	}

}
