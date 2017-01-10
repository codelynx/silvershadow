//
//	PointsShaders.metal
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 1/11/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;
float4x4 invert(float4x4 matrix);

struct VertexIn {
	float2 position [[ attribute(0) ]];
	float2 attributes [[ attribute(1) ]];
};

struct VertexOut {
	float4 position [[ position ]];
	float pointSize [[ point_size ]];
};

struct Uniforms {
	float4x4 transform;
	float zoomScale;
	float unused2;
	float unused3;
	float unused4;
};

vertex VertexOut points_vertex(
	device VertexIn * vertices [[ buffer(0) ]],
	constant Uniforms & uniforms [[ buffer(1) ]],
	uint vid [[ vertex_id ]]
) {
	VertexIn inVertex = vertices[vid];
	VertexOut outVertex;
	outVertex.position = uniforms.transform * float4(inVertex.position, 0.0, 1.0);
	float pointWidth = inVertex.attributes[0];
	outVertex.pointSize = pointWidth * uniforms.zoomScale;
	return outVertex;
}

fragment float4 points_fragment(
	VertexOut vertexIn [[ stage_in ]],
	texture2d<float, access::sample> colorTexture [[ texture(0) ]],
	sampler colorSampler [[ sampler(0) ]],
	float2 texcoord [[ point_coord ]]
) {
	
	float4 color = colorTexture.sample(colorSampler, texcoord);
	if (color.a < 0.1) {
		discard_fragment();
	}
	return color;
}
