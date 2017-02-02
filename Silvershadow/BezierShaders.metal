//
//  BezierKernel.metal
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 1/7/17.
//  Copyright © 2017 Electricwoods LLC. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

enum PathElementType {
	PathElementTypeLineTo = 2,
	PathElementTypeQuadCurveTo = 3,
	PathElementTypeCurveTo = 4
};


struct PathElement {
	unsigned char type;
	unsigned char unused1;
	unsigned char unused2;
	unsigned char unused3;

	unsigned short numberOfVertexes; // number of vertexes to produce (32 bit)
	unsigned short vertexIndex; // index to store (32-bit?)

	unsigned short width1; // width start
	unsigned short width2; // width end
	unsigned short unused4; // width start
	unsigned short unused5; // width end

	float2 p0;
	float2 p1;
	float2 p2; // may be nan
	float2 p3; // may be nan
};

struct Vertex {
	half2 position;
	half2 width_unused;

	Vertex(half2 position, half width) {
		this->position = position;
		this->width_unused = half2(width, 0.0);
	}
};

kernel void bezier_kernel(
	constant PathElement* elements [[ buffer(0) ]],
	device Vertex* outVertexes [[ buffer(1) ]],
	uint id [[ thread_position_in_grid ]]
) {
	PathElement element = elements[id];
	int numberOfVertexes = element.numberOfVertexes;

	float2 p0 = element.p0;
	float2 p1 = element.p1;
	float2 p2 = element.p2;
	float2 p3 = element.p3;
	float w1 = float(element.width1);
	float w2 = float(element.width2);
	
//	Vertex v = Vertex(p0, float(element.numberOfVertexes));
//	outVertexes[0] = v;
//	return;
	
	switch (element.type) {
	case PathElementTypeLineTo:
		for (int index = 0 ; index < numberOfVertexes ; index++) {
			float t = float(index) / float(numberOfVertexes);  // 0.0 ... 1.0
			float2 q = p0 + (p1 - p0) * t;
			float w = w1 + (w2 - w1) * t;
			Vertex v = Vertex(half2(q.x, q.y), half(w));
			outVertexes[element.vertexIndex + index] = v;
		}
		break;
	case PathElementTypeQuadCurveTo:
		for (int index = 0 ; index < numberOfVertexes ; index++) {
			float t = float(index) / float(numberOfVertexes);  // 0.0 ... 1.0
			float2 q1 = p0 + (p1 - p0) * t;
			float2 q2 = p1 + (p2 - p1) * t;
			float2 r = q1 + (q2 - q1) * t;
			float w = w1 + (w2 - w1) * t;
			Vertex v = Vertex(half2(r.x, r.y), half(w));
			outVertexes[element.vertexIndex + index] = v;
		}
		break;
	case PathElementTypeCurveTo:
		for (int index = 0 ; index < numberOfVertexes ; index++) {
			float t = float(index) / float(numberOfVertexes);  // 0.0 ... 1.0
			float2 q1 = p0 + (p1 - p0) * t;
			float2 q2 = p1 + (p2 - p1) * t;
			float2 q3 = p2 + (p3 - p2) * t;
			float2 r1 = q1 + (q2 - q1) * t;
			float2 r2 = q2 + (q3 - q2) * t;
			float2 s = r1 + (r2 - r1) * t;
			float w = w1 + (w2 - w1) * t;
			Vertex v = Vertex(half2(s.x, s.y), half(w));
			outVertexes[element.vertexIndex + index] = v;
		}
		break;
	}
}

struct VertexIn { // should be same as Vertex
	half2 position [[ attribute(0) ]];
	half2 width_unused [[ attribute(1) ]];
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

vertex VertexOut bezier_vertex(
	device VertexIn * vertices [[ buffer(0) ]],
	constant Uniforms & uniforms [[ buffer(1) ]],
	uint vid [[ vertex_id ]]
) {
	VertexIn inVertex = vertices[vid];
	VertexOut outVertex;
	
	outVertex.position = uniforms.transform * float4(float2(inVertex.position), 0.0, 1.0);
	outVertex.pointSize = vertices->width_unused[0] * uniforms.zoomScale;
	return outVertex;
}

fragment float4 bezier_fragment(
	VertexOut vertexIn [[ stage_in ]],
	texture2d<float, access::sample> colorTexture [[ texture(0) ]],
	sampler colorSampler [[ sampler(0) ]],
	float2 texcoord [[ point_coord ]]
) {
	float4 color = colorTexture.sample(colorSampler, texcoord);
//	color.g = 0;
//	color.b = 0;
	if (color.a == 0.0) {
		discard_fragment();
	}
	return color;
}
