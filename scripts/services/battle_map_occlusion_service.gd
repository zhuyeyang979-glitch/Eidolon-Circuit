extends RefCounted
class_name BattleMapOcclusionService

const MAP_OCCLUSION_NONE := "none"
const MAP_OCCLUSION_SOLID := "solid"
const MAP_OCCLUSION_CAGE := "cage"
const MAP_OCCLUSION_ONE_WAY := "one_way"
const MAP_OCCLUSION_REFLECTOR := "reflector"


func occlusion_kind_for_data(data: Dictionary, fallback: Dictionary = {}) -> String:
	var material_class := String(data.get("material_class", fallback.get("material_class", ""))).to_lower()
	var shape := String(data.get("shape", fallback.get("shape", ""))).to_lower()
	var family := String(data.get("panel_family", fallback.get("panel_family", ""))).to_lower()
	if bool(data.get("is_one_way_shield", fallback.get("is_one_way_shield", false))) or material_class == "one_way_shield":
		return MAP_OCCLUSION_ONE_WAY
	if bool(data.get("is_cage_wall", fallback.get("is_cage_wall", false))):
		return MAP_OCCLUSION_CAGE
	if bool(data.get("reflect_projectiles", fallback.get("reflect_projectiles", false))) or material_class == "reflector" or family == "reflector":
		return MAP_OCCLUSION_REFLECTOR
	if material_class in ["barrier_wall", "signal_jammer"] or material_class.contains("wall_joint") or material_class.contains("corner_joint"):
		return MAP_OCCLUSION_SOLID
	if family == "wall" or shape.contains("wall") or shape.contains("bulkhead") or shape.contains("cage") or shape.contains("corner"):
		return MAP_OCCLUSION_SOLID
	return MAP_OCCLUSION_NONE


func one_way_projectile_pass_intent(context: Dictionary) -> Dictionary:
	var mode := String(context.get("pass_mode", "directional"))
	var attacker_owner := int(context.get("attacker_owner", 0))
	var shield_owner := int(context.get("shield_owner", 0))
	if mode in ["iff", "ally"]:
		var allied := attacker_owner == shield_owner
		return {
			"passes": allied,
			"reason": "allied_owner" if allied else "foreign_owner",
		}
	if mode == "enemy":
		var enemy := attacker_owner != shield_owner
		return {
			"passes": enemy,
			"reason": "enemy_owner" if enemy else "same_owner",
		}
	var attack_direction := _vec(context.get("attack_direction", Vector2.ZERO))
	var direction_sign := signf(attack_direction.x)
	var used_attacker_facing := direction_sign == 0.0
	if used_attacker_facing:
		direction_sign = float(context.get("attacker_facing", 1.0))
	var pass_facing := float(context.get("shield_facing", 1.0))
	if String(context.get("pass_direction", "facing")) == "reverse":
		pass_facing *= -1.0
	var passes := direction_sign == pass_facing
	return {
		"passes": passes,
		"reason": "direction_allowed" if passes else "direction_blocked",
		"direction_sign": direction_sign,
		"pass_facing": pass_facing,
		"used_attacker_facing": used_attacker_facing,
	}


func path_collider_for_event(context: Dictionary) -> Dictionary:
	if not bool(context.get("attacker_live", true)):
		return {}
	var fallback_direction := _normalized_or(_vec(context.get("fallback_direction", Vector2.RIGHT)), Vector2.RIGHT)
	var direction := _normalized_or(_vec(context.get("direction", fallback_direction)), fallback_direction)
	var start := _vec(context.get("start", Vector2.ZERO))
	var path_range := maxf(0.04, float(context.get("range", context.get("projectile_range", context.get("default_range", 1.0)))))
	var width := maxf(float(context.get("projectile_width_m", 0.0)), float(context.get("lane_range", 0.08)))
	return {
		"shape": "capsule",
		"a": start,
		"b": start + direction * path_range,
		"radius": maxf(0.018, width * 0.5),
	}


func path_collider_between(context: Dictionary) -> Dictionary:
	if not bool(context.get("attacker_live", true)) or not bool(context.get("target_live", true)):
		return {}
	var start := _vec(context.get("start", Vector2.ZERO))
	var delta := _vec(context.get("delta", Vector2.ZERO))
	if delta.length() <= 0.01:
		return {}
	var width := maxf(float(context.get("projectile_width_m", 0.0)), float(context.get("lane_range", 0.08)))
	return {
		"shape": "capsule",
		"a": start,
		"b": start + delta,
		"radius": maxf(0.018, width * 0.5),
	}


func blocker_candidate_intent(context: Dictionary) -> Dictionary:
	var kind := String(context.get("kind", MAP_OCCLUSION_NONE))
	if kind == MAP_OCCLUSION_NONE:
		return {"action": "reject", "reason": "non_occluding"}
	var gap := float(context.get("gap", INF))
	if gap > 0.0:
		return {"action": "reject", "reason": "outside_path", "gap": gap}
	if kind == MAP_OCCLUSION_ONE_WAY and bool(context.get("one_way_pass", false)):
		return {"action": "reject", "reason": "one_way_pass"}
	var start := _vec(context.get("start", Vector2.ZERO))
	var direction := _normalized_or(_vec(context.get("direction", Vector2.RIGHT)), Vector2.RIGHT)
	var path_length := float(context.get("path_length", 0.0))
	if path_length <= 0.01:
		return {"action": "reject", "reason": "invalid_path"}
	var center := _vec(context.get("center", start))
	var projection := (center - start).dot(direction)
	var extent := maxf(0.0, float(context.get("extent", 0.0)))
	if projection < -extent or projection > path_length + extent:
		return {"action": "reject", "reason": "outside_projection", "projection": projection}
	var distance := clampf(projection, 0.0, path_length)
	return {
		"action": "accept",
		"kind": kind,
		"blocker_name": String(context.get("blocker_name", "")),
		"position": start + direction * distance,
		"distance": distance,
		"projection": projection,
		"gap": gap,
		"candidate_index": int(context.get("candidate_index", -1)),
		"collider": _dict(context.get("collider", {})).duplicate(true),
	}


func occlusion_query_from_candidates(context: Dictionary) -> Dictionary:
	var candidates: Array = Array(context.get("candidates", []))
	var best: Dictionary = {}
	var best_distance := INF
	for raw_candidate in candidates:
		var candidate := _dict(raw_candidate)
		if candidate.is_empty():
			continue
		if String(candidate.get("action", "accept")) == "reject":
			continue
		var distance := float(candidate.get("distance", INF))
		if distance < 0.0 or distance >= best_distance:
			continue
		best_distance = distance
		best = {
			"kind": String(candidate.get("kind", MAP_OCCLUSION_NONE)),
			"blocker_name": String(candidate.get("blocker_name", "")),
			"position": candidate.get("position", Vector2.ZERO),
			"distance": distance,
			"candidate_index": int(candidate.get("candidate_index", -1)),
			"collider": _dict(candidate.get("collider", {})).duplicate(true),
		}
	return best


func occlusion_kind_from_query(query: Dictionary) -> String:
	return String(query.get("kind", MAP_OCCLUSION_NONE))


func line_occluded(query: Dictionary) -> bool:
	return occlusion_kind_from_query(query) != MAP_OCCLUSION_NONE


func line_of_sight_clear(query: Dictionary) -> bool:
	return not line_occluded(query)


func _normalized_or(value: Vector2, fallback: Vector2) -> Vector2:
	var result := value
	if result.length() <= 0.01:
		result = fallback
	if result.length() <= 0.01:
		result = Vector2.RIGHT
	return result.normalized()


func _vec(value, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	return value if value is Vector2 else fallback


func _dict(value) -> Dictionary:
	return value if value is Dictionary else {}
