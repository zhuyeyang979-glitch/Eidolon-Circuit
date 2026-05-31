#[compute]
#version 450

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

const uint COLLIDER_STRIDE = 80u;
const uint QUERY_STRIDE = 16u;
const uint HIT_STRIDE = 16u;
const uint MAX_VERTS = 24u;

layout(set = 0, binding = 0, std430) restrict readonly buffer ColliderBuffer {
	float c[];
} colliders;

layout(set = 0, binding = 1, std430) restrict readonly buffer QueryBuffer {
	float q[];
} queries;

layout(set = 0, binding = 2, std430) restrict writeonly buffer HitBuffer {
	float h[];
} hits;

layout(set = 0, binding = 3, std430) restrict buffer CounterBuffer {
	uint counts[];
} counters;

layout(set = 0, binding = 4, std430) restrict readonly buffer ParamBuffer {
	float p[];
} params;

vec2 c2(uint collider_index, uint offset) {
	uint base = collider_index * COLLIDER_STRIDE + offset;
	return vec2(colliders.c[base], colliders.c[base + 1u]);
}

float cf(uint collider_index, uint offset) {
	return colliders.c[collider_index * COLLIDER_STRIDE + offset];
}

vec2 q2(uint query_index, uint offset) {
	uint base = query_index * QUERY_STRIDE + offset;
	return vec2(queries.q[base], queries.q[base + 1u]);
}

float qf(uint query_index, uint offset) {
	return queries.q[query_index * QUERY_STRIDE + offset];
}

vec2 vertex_at(uint collider_index, uint vertex_index) {
	uint base = collider_index * COLLIDER_STRIDE + 18u + vertex_index * 2u;
	return vec2(colliders.c[base], colliders.c[base + 1u]);
}

float cross2(vec2 a, vec2 b) {
	return a.x * b.y - a.y * b.x;
}

bool segment_intersection(vec2 a, vec2 b, vec2 c, vec2 d, out float t, out vec2 point, out vec2 normal) {
	vec2 r = b - a;
	vec2 s = d - c;
	float denom = cross2(r, s);
	if (abs(denom) < 0.000001) {
		return false;
	}
	vec2 ca = c - a;
	float next_t = cross2(ca, s) / denom;
	float u = cross2(ca, r) / denom;
	if (next_t < 0.0 || next_t > 1.0 || u < 0.0 || u > 1.0) {
		return false;
	}
	t = next_t;
	point = a + r * t;
	vec2 edge = d - c;
	normal = normalize(vec2(-edge.y, edge.x));
	vec2 dir = normalize(r);
	if (dot(normal, dir) > 0.0) {
		normal = -normal;
	}
	return true;
}

float point_segment_distance(vec2 p, vec2 a, vec2 b, out float t, out vec2 closest) {
	vec2 ab = b - a;
	float denom = max(dot(ab, ab), 0.000001);
	t = clamp(dot(p - a, ab) / denom, 0.0, 1.0);
	closest = a + ab * t;
	return length(p - closest);
}

void write_hit(uint query_index, uint collider_index, float distance, vec2 position, vec2 normal, float projection, float strength, float kind, uint max_hits) {
	uint hit_index = atomicAdd(counters.counts[0], 1u);
	if (hit_index >= max_hits) {
		counters.counts[1] = 1u;
		return;
	}
	uint base = hit_index * HIT_STRIDE;
	hits.h[base + 0u] = 1.0;
	hits.h[base + 1u] = float(query_index);
	hits.h[base + 2u] = float(collider_index);
	hits.h[base + 3u] = distance;
	hits.h[base + 4u] = position.x;
	hits.h[base + 5u] = position.y;
	hits.h[base + 6u] = normal.x;
	hits.h[base + 7u] = normal.y;
	hits.h[base + 8u] = projection;
	hits.h[base + 9u] = strength;
	hits.h[base + 10u] = kind;
}

void main() {
	uint collider_count = uint(max(params.p[0], 0.0));
	uint query_count = uint(max(params.p[1], 0.0));
	uint max_hits = uint(max(params.p[2], 0.0));
	uint total = collider_count * query_count;
	uint global_index = gl_GlobalInvocationID.x;
	if (global_index >= total || max_hits == 0u || collider_count == 0u || query_count == 0u) {
		return;
	}
	uint query_index = global_index / collider_count;
	uint collider_index = global_index - query_index * collider_count;
	if (qf(query_index, 0u) < 0.5 || cf(collider_index, 0u) < 0.5) {
		return;
	}
	if (abs(qf(query_index, 1u) - cf(collider_index, 1u)) < 0.5) {
		return;
	}
	if (qf(query_index, 10u) < 0.5 && abs(qf(query_index, 2u) - cf(collider_index, 2u)) < 0.5) {
		return;
	}

	vec2 start = q2(query_index, 4u);
	vec2 end = q2(query_index, 6u);
	vec2 segment = end - start;
	float segment_len = length(segment);
	if (segment_len < 0.0001) {
		return;
	}
	vec2 dir = segment / segment_len;
	float max_distance = min(max(qf(query_index, 9u), 0.0), segment_len);
	vec2 query_end = start + dir * max_distance;
	float radius = max(qf(query_index, 8u), 0.0);

	vec2 cmin = c2(collider_index, 6u) - vec2(radius);
	vec2 cmax = c2(collider_index, 8u) + vec2(radius);
	vec2 smin = min(start, query_end);
	vec2 smax = max(start, query_end);
	if (smax.x < cmin.x || cmax.x < smin.x || smax.y < cmin.y || cmax.y < smin.y) {
		return;
	}

	uint count = uint(max(0.0, min(cf(collider_index, 11u), float(MAX_VERTS))));
	if (count < 3u) {
		return;
	}
	float best_t = 3.402823466e+38;
	vec2 best_point = vec2(0.0);
	vec2 best_normal = -dir;
	bool found = false;
	for (uint i = 0u; i < count; i++) {
		vec2 p0 = vertex_at(collider_index, i);
		vec2 p1 = vertex_at(collider_index, (i + 1u) % count);
		float t;
		vec2 point;
		vec2 normal;
		if (segment_intersection(start, query_end, p0, p1, t, point, normal)) {
			if (t < best_t) {
				best_t = t;
				best_point = point;
				best_normal = normal;
				found = true;
			}
		} else if (radius > 0.0001) {
			float closest_t;
			vec2 closest;
			float dist = point_segment_distance(p0, start, query_end, closest_t, closest);
			if (dist <= radius && closest_t < best_t) {
				best_t = closest_t;
				best_point = closest;
				best_normal = normalize(closest - p0);
				if (length(best_normal) < 0.0001) {
					best_normal = -dir;
				}
				found = true;
			}
		}
	}
	if (!found) {
		return;
	}
	float distance = best_t * max_distance;
	write_hit(query_index, collider_index, distance, best_point, best_normal, distance, max(radius, 0.01), 1.0, max_hits);
}
