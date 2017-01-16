//
//	BrushShaders.metal
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 1/11/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;
float4x4 invert(float4x4 matrix);

//
//	BrushShape
//

struct BrushShapeVertexIn {
	float2 position [[ attribute(0) ]];
	float2 attributes [[ attribute(1) ]];
};

struct BrushShapeVertexOut {
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

vertex BrushShapeVertexOut brush_shape_vertex(
	device BrushShapeVertexIn * vertices [[ buffer(0) ]],
	constant Uniforms & uniforms [[ buffer(1) ]],
	uint vid [[ vertex_id ]]
) {
	BrushShapeVertexIn inVertex = vertices[vid];
	BrushShapeVertexOut outVertex;
	outVertex.position = uniforms.transform * float4(inVertex.position, 0.0, 1.0);
	float pointWidth = inVertex.attributes[0];
	outVertex.pointSize = pointWidth * uniforms.zoomScale;
	return outVertex;
}

fragment float4 brush_shape_fragment(
	BrushShapeVertexOut vertexIn [[ stage_in ]],
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

//
//	BrushFill
//

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

vertex BrushFillVertexOut brush_fill_vertex(
	device BrushFillVertexIn * vertices [[ buffer(0) ]],
	constant Uniforms & uniforms [[ buffer(1) ]],
	uint vid [[ vertex_id ]]
) {
	BrushFillVertexOut outVertex;
	BrushFillVertexIn inVertex = vertices[vid];
	outVertex.position = float4(inVertex.position);
	outVertex.maskTexcoords = inVertex.maskTexcoords;
	outVertex.patternTexcoords = inVertex.patternTexcoords;
	return outVertex;
}

fragment float4 brush_fill_fragment(
	BrushFillVertexOut vertexIn [[ stage_in ]],
	texture2d<float, access::sample> maskTexture [[ texture(0) ]],
	texture2d<float, access::sample> patternTexture [[ texture(1) ]],
	sampler maskSampler [[ sampler(0) ]],
	sampler patternSampler [[ sampler(1) ]]
) {
	float mask = maskTexture.sample(maskSampler, vertexIn.maskTexcoords).a;
	float4 pattern = patternTexture.sample(patternSampler, vertexIn.patternTexcoords);
	return float4(pattern.rgb, pattern.a * mask);
}

