//
//  PatternShader.metal
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 1/15/17.
//  Copyright © 2017 Electricwoods LLC. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

/*
struct BrushFillVertexIn {
	packed_float4 position [[ attribute(0) ]];
	packed_float2 maskTexcoords [[ attribute(1) ]];
	packed_float2 patternTexcoords [[ attribute(2) ]];
};

struct BrushFillVertexOut {
	float4 position [[ position ]];
	float2 maskTexcoords;
	float2 patternTexcoords;
};

struct BrushFillUniforms {
	float4x4 modelViewProjectionMatrix;
};

vertex BrushFillVertexOut pattern_vertex(
	device BrushFillVertexIn * vertices [[ buffer(0) ]],
	constant BrushFillUniforms & uniforms [[ buffer(1) ]],
	uint vid [[ vertex_id ]]
) {
	BrushFillVertexOut outVertex;
	BrushFillVertexIn inVertex = vertices[vid];
	outVertex.position = uniforms.modelViewProjectionMatrix * float4(inVertex.position);
	outVertex.maskTexcoords = inVertex.maskTexcoords;
	outVertex.patternTexcoords = inVertex.patternTexcoords;
	return outVertex;
}

fragment float4 pattern_fragment(
	BrushFillVertexOut vertexIn [[ stage_in ]],
	texture2d<float, access::sample> maskTexture [[ texture(0) ]],
	texture2d<float, access::sample> patternTexture [[ texture(1) ]],
	sampler maskSampler [[ sampler(0) ]],
	sampler patternSampler [[ sampler(1) ]]
) {
	float mask = maskTexture.sample(maskSampler, vertexIn.maskTexcoords).a;
	float3 pattern = patternTexture.sample(patternSampler, vertexIn.patternTexcoords).rgb;
	return float4(pattern, mask);
}
*/

