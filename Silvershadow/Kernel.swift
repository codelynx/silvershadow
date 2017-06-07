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

final class KernelRegistry : DictLike<String, Kernel> { }

final class KernelMap : NSMapTable<MTLDevice, KernelRegistry> {
    static let shared = KernelMap.weakToStrongObjects()
}

extension MTLDevice {

	func kernel<T: Kernel>() -> T {
		let key = NSStringFromClass(T.self)
		let registry = KernelMap.shared.object(forKey: self) ?? KernelRegistry()
		let renderer = registry[key] ?? T(device: self)
		registry[key] = renderer
		KernelMap.shared.setObject(registry, forKey: self)
		return renderer as! T
	}

}
