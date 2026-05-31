class_name GameplayTransform

const DEFAULT_LOOP_LENGTH := 24.0
const DEFAULT_HITBOX_SCALE_STRENGTH := 1.0
const DEFAULT_HITBOX_SCALE_MIN := 0.70
const DEFAULT_HITBOX_SCALE_MAX := 1.30


static func coord(unit) -> Vector2:
	if unit != null and is_instance_valid(unit) and unit.get("mobius_s") != null:
		return Vector2(float(unit.get("mobius_s")), float(unit.get("mobius_v")))
	if unit != null and is_instance_valid(unit):
		return Vector2(float(unit.ring_pos), float(unit.lane))
	return Vector2.ZERO


static func nearest_lifted_s(reference_s: float, ring_value: float, loop_length: float = DEFAULT_LOOP_LENGTH) -> float:
	var loop := maxf(0.001, loop_length)
	var base := fposmod(ring_value, loop)
	var sheet := roundf((reference_s - base) / loop)
	return base + sheet * loop


static func lift_ring_lane_near(reference_s: float, ring_value: float, lane_value: float, loop_length: float = DEFAULT_LOOP_LENGTH) -> Vector2:
	var loop := maxf(0.001, loop_length)
	var lifted_s := nearest_lifted_s(reference_s, ring_value, loop)
	var sheet := int(roundf((lifted_s - fposmod(ring_value, loop)) / loop))
	var lifted_v := lane_value
	if abs(sheet) % 2 == 1:
		lifted_v = -lifted_v
	return Vector2(lifted_s, lifted_v)


static func delta(from_coord: Vector2, to_coord: Vector2, loop_length: float = DEFAULT_LOOP_LENGTH) -> Vector2:
	var loop := maxf(0.001, loop_length)
	var best := Vector2(to_coord.x - from_coord.x, to_coord.y - from_coord.y)
	var best_len_sq := best.length_squared()
	var center_sheet := int(roundf((from_coord.x - to_coord.x) / loop))
	for offset in range(-3, 4):
		var sheet := center_sheet + offset
		var candidate_s := to_coord.x + float(sheet) * loop
		var candidate_v := to_coord.y
		if abs(sheet) % 2 == 1:
			candidate_v = -candidate_v
		var candidate := Vector2(candidate_s - from_coord.x, candidate_v - from_coord.y)
		var candidate_len_sq := candidate.length_squared()
		if candidate_len_sq < best_len_sq:
			best = candidate
			best_len_sq = candidate_len_sq
	return best


static func unit_delta(from_unit, to_unit, loop_length: float = DEFAULT_LOOP_LENGTH, lane_scale: float = 1.0) -> Vector2:
	var result := delta(coord(from_unit), coord(to_unit), loop_length)
	result.y *= lane_scale
	return result


static func point_delta(from_ring: float, from_lane: float, to_ring: float, to_lane: float, reference_s: float, loop_length: float = DEFAULT_LOOP_LENGTH, lane_scale: float = 1.0) -> Vector2:
	var from_coord := lift_ring_lane_near(reference_s, from_ring, from_lane, loop_length)
	var to_coord := lift_ring_lane_near(from_coord.x, to_ring, to_lane, loop_length)
	var result := delta(from_coord, to_coord, loop_length)
	result.y *= lane_scale
	return result


static func unit_to_point_delta(unit, to_ring: float, to_lane: float, loop_length: float = DEFAULT_LOOP_LENGTH, lane_scale: float = 1.0) -> Vector2:
	var from_coord := coord(unit)
	var to_coord := lift_ring_lane_near(from_coord.x, to_ring, to_lane, loop_length)
	var result := delta(from_coord, to_coord, loop_length)
	result.y *= lane_scale
	return result


static func screen_input_to_gameplay_motion(input_vector: Vector2) -> Vector2:
	if input_vector.length() <= 0.04:
		return Vector2.ZERO
	return input_vector.normalized() if input_vector.length() > 1.0 else input_vector


static func projectile_ray(start: Vector2, direction: Vector2, range: float) -> Dictionary:
	var dir := direction.normalized() if direction.length() > 0.01 else Vector2.RIGHT
	var reach := maxf(0.0, range)
	return {"start": start, "end": start + dir * reach, "direction": dir, "range": reach}


static func hitbox_scale_for_visual_scale(visual_scale: float, strength: float = DEFAULT_HITBOX_SCALE_STRENGTH, min_scale: float = DEFAULT_HITBOX_SCALE_MIN, max_scale: float = DEFAULT_HITBOX_SCALE_MAX) -> float:
	var raw := lerpf(1.0, maxf(0.001, visual_scale), clampf(strength, 0.0, 1.0))
	return clampf(raw, min_scale, max_scale)
