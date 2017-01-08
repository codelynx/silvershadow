//
//  BezierKernel.metal
//  Silvershadow
//
//  Created by Kaz Yoshikawa on 1/7/17.
//  Copyright © 2017 Electricwoods LLC. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;



struct Point {
	float x;
	float y;
	
	Point(float x, float y) {
		this->x = x;
		this->y = y;
	}
	
	bool isNan() {
		return isnan(x) || isnan(y);
	}
};

Point add(Point a, Point b);
Point subtract(Point a, Point b);
Point multiply(Point a, float b);


Point add(Point a, Point b) {
	return Point(a.x + b.x, a.y + b.y);
}

Point subtract(Point a, Point b) {
	return Point(a.x - b.x, a.y - b.y);
}

Point multiply(Point a, float b) {
	return Point(a.x * b, a.y * b);
}

struct PathElement {
	int numberOfVertexes; // 32-bit
	int vertexIndex;
	float startWidth;
	float endWidth;
	Point p0;
	Point p1;
	Point p2; // may be nan
	Point p3; // may be nan
};

struct Vertex {
	float x;
	float y;
	float width;
	float unused;

	Vertex(float x, float y, float width) {
		this->x = x;
		this->y = y;
		this->width = width;
		this->unused = 0;
	}
};

struct VertexArray {
	Vertex out[1024];
};

kernel void compute_bezier_kernel(
	constant PathElement* elements [[ buffer(0) ]],
	device Vertex* outVertexes [[ buffer(1) ]]
//	uint id [[ thread_position_in_grid ]]
) {
	uint id = 0;
	PathElement element = elements[id];
	int numberOfVertexes = element.numberOfVertexes;
	Point p0 = element.p0;
	Point p1 = element.p1;
	Point p2 = element.p2;
	Point p3 = element.p3;
	float widthRatio = (element.endWidth - element.startWidth) / float(numberOfVertexes);
	
	if (p0.isNan() && p1.isNan()) {
	}
	else if (p2.isNan()) {
		for (int index = 0 ; index < numberOfVertexes ; index++) {
			float t = float(index) / float(numberOfVertexes);  // 0.0 ... 1.0
			Point q = add(p0, multiply(subtract(p1, p0), t));
			float width = element.startWidth + (widthRatio * t);
			Vertex v = Vertex(q.x, q.y, width);
			outVertexes[element.vertexIndex + index] = v;
		}
	}
	else if (p3.isNan()) {
		for (int index = 0 ; index < numberOfVertexes ; index++) {
			float t = float(index) / float(numberOfVertexes);  // 0.0 ... 1.0
			Point q1 = add(p0, multiply(subtract(p1, p0), t));
			Point q2 = add(p1, multiply(subtract(p2, p1), t));
			Point r = add(q1, multiply(subtract(q2, q1), t));
			float width = element.startWidth + (widthRatio * t);
			Vertex v = Vertex(r.x, r.y, width);
			outVertexes[element.vertexIndex + index] = v;
		}
	}
	else {
		for (int index = 0 ; index < numberOfVertexes ; index++) {
			float t = float(index) / float(numberOfVertexes);  // 0.0 ... 1.0
			Point q1 = add(p0, multiply(subtract(p1, p0), t));
			Point q2 = add(p1, multiply(subtract(p2, p1), t));
			Point q3 = add(p2, multiply(subtract(p3, p2), t));

			Point r1 = add(q1, multiply(subtract(q2, q1), t));
			Point r2 = add(q2, multiply(subtract(q3, q2), t));

			Point s = add(r1, multiply(subtract(r2, r1), t));

			float width = element.startWidth + (widthRatio * t);
			Vertex v = Vertex(s.x, s.y, width);
			outVertexes[element.vertexIndex + index] = v;
		}
	}
}
