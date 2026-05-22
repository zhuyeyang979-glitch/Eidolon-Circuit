#[compute]
#version 450

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

const uint COLLIDER_STRIDE = 80u;
const uint RESPONSE_STRIDE = 28u;
const uint MAX_VERTS = 24u;
const uint FLAG_ANCHORED = 1u;

layout(set = 0, binding = 0, std430) restrict readonly buffer ColliderBuffer {
	float c[];
} colliders;

layout(set = 0, binding = 1, std430) restrict readonly buffer CandidateBuffer {
	uint p[];
} candidates;

layout(set = 0, binding = 2, std430) restrict writeonly buffer ResponseBuffer {
	float r[];
} responses;

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

bool has_flag(uint collider_index, uint flag_value) {
	uint flags = uint(max(0.0, floor(cf(collider_index, 3u) + 0.5)));
	return (flags & flag_value) != 0u;
}

vec2 vertex_at(uint collider_index, uint vertex_index) {
	uint base = collider_index * COLLIDER_STRIDE + 18u + vertex_index * 2u;
	return vec2(colliders.c[base], colliders.c[base + 1u]);
}

void project_polygon(uint collider_index, vec2 axis, out float min_v, out float max_v) {
	uint count = uint(max(0.0, min(cf(collider_index, 11u), float(MAX_VERTS))));
	if (count == 0u) {
		float center_dot = dot(c2(collider_index, 4u), axis);
		min_v = center_dot;
		max_v = center_dot;
		return;
	}
	float first = dot(vertex_at(collider_index, 0u), axis);
	min_v = first;
	max_v = first;
	for (uint i = 1u; i < count; i++) {
		float d = dot(vertex_at(collider_index, i), axis);
		min_v = min(min_v, d);
		max_v = max(max_v, d);
	}
}

bool test_axis(uint a, uint b, vec2 axis, inout float best_overlap, inout vec2 best_axis) {
	float len = length(axis);
	if (len < 0.00001) {
		return true;
	}
	axis /= len;
	float min_a;
	float max_a;
	float min_b;
	float max_b;
	project_polygon(a, axis, min_a, max_a);
	project_polygon(b, axis, min_b, max_b);
	float overlap = min(max_a, max_b) - max(min_a, min_b);
	if (overlap <= 0.0) {
		return false;
	}
	if (overlap < best_overlap) {
		vec2 center_delta = c2(b, 4u) - c2(a, 4u);
		if (dot(axis, center_delta) < 0.0) {
			axis = -axis;
		}
		best_overlap = overlap;
		best_axis = axis;
	}
	return true;
}

bool sat_overlap(uint a, uint b, out vec2 normal, out float penetration) {
	uint count_a = uint(max(0.0, min(cf(a, 11u), float(MAX_VERTS))));
	uint count_b = uint(max(0.0, min(cf(b, 11u), float(MAX_VERTS))));
	if (count_a < 3u || count_b < 3u) {
		return false;
	}
	float best_overlap = 3.402823466e+38;
	vec2 best_axis = normalize(c2(b, 4u) - c2(a, 4u));
	if (length(best_axis) < 0.00001) {
		best_axis = vec2(1.0, 0.0);
	}
	for (uint i = 0u; i < count_a; i++) {
		vec2 p0 = vertex_at(a, i);
		vec2 p1 = vertex_at(a, (i + 1u) % count_a);
		vec2 axis = vec2(-(p1.y - p0.y), p1.x - p0.x);
		if (!test_axis(a, b, axis, best_overlap, best_axis)) {
			return false;
		}
	}
	for (uint i = 0u; i < count_b; i++) {
		vec2 p0 = vertex_at(b, i);
		vec2 p1 = vertex_at(b, (i + 1u) % count_b);
		vec2 axis = vec2(-(p1.y - p0.y), p1.x - p0.x);
		if (!test_axis(a, b, axis, best_overlap, best_axis)) {
			return false;
		}
	}
	normal = best_axis;
	penetration = best_overlap;
	return true;
}

void main() {
	uint max_candidates = uint(max(params.p[4], 0.0));
	uint max_responses = uint(max(params.p[5], 0.0));
	uint candidate_count = min(counters.counts[0], max_candidates);
	uint candidate_index = gl_GlobalInvocationID.x;
	if (candidate_index >= candidate_count || max_responses == 0u) {
		return;
	}

	uint a = candidates.p[candidate_index * 2u];
	uint b = candidates.p[candidate_index * 2u + 1u];
	if (cf(a, 0u) < 0.5 || cf(b, 0u) < 0.5) {
		return;
	}
	if (abs(cf(a, 1u) - cf(b, 1u)) < 0.5) {
		return;
	}

	vec2 normal;
	float penetration;
	if (!sat_overlap(a, b, normal, penetration)) {
		return;
	}
	if (penetration <= params.p[2]) {
		return;
	}

	uint response_index = atomicAdd(counters.counts[1], 1u);
	if (response_index >= max_responses) {
		counters.counts[2] = 2u;
		return;
	}

	vec2 va = c2(a, 12u);
	vec2 vb = c2(b, 12u);
	float relative_normal_velocity = dot(va - vb, normal);
	float closing_speed = max(0.0, relative_normal_velocity);
	float mass_a = max(1.0, cf(a, 14u));
	float mass_b = max(1.0, cf(b, 14u));
	float raw_momentum = closing_speed * (mass_a + mass_b);
	float stiffness_a = max(1.0, cf(a, 15u));
	float stiffness_b = max(1.0, cf(b, 15u));
	float usable_momentum = min(raw_momentum, min(stiffness_a, stiffness_b));

	vec2 vel_delta_a = vec2(0.0);
	vec2 vel_delta_b = vec2(0.0);
	bool anchored_a = has_flag(a, FLAG_ANCHORED);
	bool anchored_b = has_flag(b, FLAG_ANCHORED);
	if (usable_momentum > 0.001) {
		if (!anchored_a) {
			vel_delta_a = -normal * (usable_momentum / mass_a);
		}
		if (!anchored_b) {
			vel_delta_b = normal * (usable_momentum / mass_b);
		}
	}

	float correction = min(penetration, 0.22) * clamp(0.58 + params.p[3] * 5.0, 0.58, 0.92);
	float total_mass = max(0.001, mass_a + mass_b);
	float share_a = clamp(mass_b / total_mass, 0.12, 0.88);
	float share_b = clamp(mass_a / total_mass, 0.12, 0.88);
	if (anchored_a && anchored_b) {
		share_a = 0.0;
		share_b = 0.0;
	} else if (anchored_a) {
		share_a = 0.0;
		share_b = 1.0;
	} else if (anchored_b) {
		share_a = 1.0;
		share_b = 0.0;
	}
	vec2 pos_delta_a = -normal * correction * share_a;
	vec2 pos_delta_b = normal * correction * share_b;

	float recovery_a = cf(a, 17u) > 0.5 ? 1.0 : 0.0;
	float recovery_b = cf(b, 17u) > 0.5 ? 1.0 : 0.0;
	vec2 contact_point = (c2(a, 4u) + c2(b, 4u)) * 0.5;
	float vfx_strength = max(penetration, raw_momentum * 0.004);
	float vfx_kind = raw_momentum > 0.001 ? 1.0 : 2.0;

	uint base = response_index * RESPONSE_STRIDE;
	responses.r[base + 0u] = 1.0;
	responses.r[base + 1u] = float(a);
	responses.r[base + 2u] = float(b);
	responses.r[base + 3u] = normal.x;
	responses.r[base + 4u] = normal.y;
	responses.r[base + 5u] = penetration;
	responses.r[base + 6u] = contact_point.x;
	responses.r[base + 7u] = contact_point.y;
	responses.r[base + 8u] = relative_normal_velocity;
	responses.r[base + 9u] = raw_momentum;
	responses.r[base + 10u] = usable_momentum;
	responses.r[base + 11u] = vel_delta_a.x;
	responses.r[base + 12u] = vel_delta_a.y;
	responses.r[base + 13u] = vel_delta_b.x;
	responses.r[base + 14u] = vel_delta_b.y;
	responses.r[base + 15u] = pos_delta_a.x;
	responses.r[base + 16u] = pos_delta_a.y;
	responses.r[base + 17u] = pos_delta_b.x;
	responses.r[base + 18u] = pos_delta_b.y;
	responses.r[base + 19u] = recovery_a;
	responses.r[base + 20u] = recovery_b;
	responses.r[base + 21u] = vfx_strength;
	responses.r[base + 22u] = vfx_kind;
}
