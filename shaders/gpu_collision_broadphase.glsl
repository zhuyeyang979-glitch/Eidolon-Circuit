#[compute]
#version 450

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

const uint COLLIDER_STRIDE = 80u;

layout(set = 0, binding = 0, std430) restrict readonly buffer ColliderBuffer {
	float c[];
} colliders;

layout(set = 0, binding = 1, std430) restrict writeonly buffer CandidateBuffer {
	uint p[];
} candidates;

layout(set = 0, binding = 2, std430) restrict buffer CounterBuffer {
	uint counts[];
} counters;

layout(set = 0, binding = 3, std430) restrict readonly buffer ParamBuffer {
	float p[];
} params;

vec2 c2(uint collider_index, uint offset) {
	uint base = collider_index * COLLIDER_STRIDE + offset;
	return vec2(colliders.c[base], colliders.c[base + 1u]);
}

float cf(uint collider_index, uint offset) {
	return colliders.c[collider_index * COLLIDER_STRIDE + offset];
}

void main() {
	uint collider_count = uint(max(params.p[0], 0.0));
	uint pair_count = uint(max(params.p[1], 0.0));
	uint max_candidates = uint(max(params.p[4], 0.0));
	uint pair_index = gl_GlobalInvocationID.x;
	if (pair_index >= pair_count || collider_count < 2u || max_candidates == 0u) {
		return;
	}

	uint a = 0u;
	uint remaining = pair_index;
	uint row_count = collider_count - 1u;
	while (remaining >= row_count && row_count > 0u) {
		remaining -= row_count;
		a += 1u;
		row_count -= 1u;
	}
	uint b = a + 1u + remaining;
	if (a >= collider_count || b >= collider_count) {
		return;
	}
	if (cf(a, 0u) < 0.5 || cf(b, 0u) < 0.5) {
		return;
	}
	if (abs(cf(a, 1u) - cf(b, 1u)) < 0.5) {
		return;
	}

	vec2 amin = c2(a, 6u);
	vec2 amax = c2(a, 8u);
	vec2 bmin = c2(b, 6u);
	vec2 bmax = c2(b, 8u);
	if (amax.x < bmin.x || bmax.x < amin.x || amax.y < bmin.y || bmax.y < amin.y) {
		return;
	}
	vec2 delta = c2(b, 4u) - c2(a, 4u);
	float radius_sum = cf(a, 10u) + cf(b, 10u);
	if (dot(delta, delta) > radius_sum * radius_sum) {
		return;
	}

	uint candidate_index = atomicAdd(counters.counts[0], 1u);
	if (candidate_index >= max_candidates) {
		counters.counts[2] = 1u;
		return;
	}
	candidates.p[candidate_index * 2u] = a;
	candidates.p[candidate_index * 2u + 1u] = b;
}
