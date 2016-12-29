//
//  CompositeKernel.metal
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 12/29/16.
//  Copyright © 2016 Electricwoods LLC. All rights reserved.
//

#include <metal_stdlib>
#include <metal_texture>
using namespace metal;


kernel void composite_kernel(
		texture2d<float, access::read> source [[texture(0)]],
		texture2d<float, access::read_write> destination [[texture(1)]],
		uint2 gid [[thread_position_in_grid]]
) {
	float4 src = source.read(gid);
	float4 dst = destination.read(gid);
	float4 composite;
	composite.r = (src.r * src.a) + (dst.r * (1.0f - src.a));
	composite.g = (src.g * src.a) + (dst.g * (1.0f - src.a));
	composite.b = (src.b * src.a) + (dst.b * (1.0f - src.a));
	composite.a = (src.a * src.a) + (dst.a * (1.0f - src.a));
	destination.write(composite, gid);
}

