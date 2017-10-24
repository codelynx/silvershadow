//
//	ImageShaders.metal
//	SilverShadow
//
//	Created by Kaz Yoshikawa on 12/22/15.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct VertexIn {
	float4 position [[ attribute(0) ]];
	float2 texcoords [[ attribute(1) ]];
};

struct VertexOut {
	float4 position [[ position ]];
	float2 texcoords;
};

struct Uniforms {
	float4x4 transform;
};

vertex VertexOut image_vertex(
	device VertexIn * vertices [[ buffer(0) ]],
	constant Uniforms & uniforms [[ buffer(1) ]],
	uint vid [[ vertex_id ]]
) {
	VertexOut outVertex;
	VertexIn inVertex = vertices[vid];
	outVertex.position = uniforms.transform * float4(inVertex.position);
	outVertex.texcoords = inVertex.texcoords;
	return outVertex;
}

fragment float4 image_fragment(
	VertexOut vertexIn [[ stage_in ]],
	texture2d<float, access::sample> colorTexture [[ texture(0) ]],
	sampler colorSampler [[ sampler(0) ]]
) {
	return colorTexture.sample(colorSampler, vertexIn.texcoords).rgba;
}

