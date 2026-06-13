extends RefCounted
class_name BattleImpactQueryService


func projectile_direction_intent(context: Dictionary) -> Dictionary:
	var direction := _vec(context.get("direction", Vector2.ZERO))
	var fallback := _vec(context.get("fallback_direction", Vector2.RIGHT))
	if fallback.length() <= 0.01:
		fallback = Vector2.RIGHT
	var used_fallback := direction.length() <= 0.01
	if used_fallback:
		direction = fallback
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	return {
		"direction": direction.normalized(),
		"used_fallback": used_fallback,
	}


func projectile_projection_intent(context: Dictionary) -> Dictionary:
	var missing_projection := float(context.get("missing_projection", 999999.0))
	if not bool(context.get("attacker_live", true)):
		return {"projection": missing_projection, "used_fallback": false, "reason": "attacker_gone"}
	var direction_intent := projectile_direction_intent({
		"direction": context.get("direction", Vector2.ZERO),
		"fallback_direction": context.get("fallback_direction", Vector2.RIGHT),
	})
	var direction: Vector2 = direction_intent.get("direction", Vector2.RIGHT)
	var delta := _vec(context.get("delta", Vector2.ZERO))
	return {
		"projection": delta.dot(direction),
		"direction": direction,
		"used_fallback": bool(direction_intent.get("used_fallback", false)),
	}


func true_bullet_before_locked_target_intent(context: Dictionary) -> Dictionary:
	var unit_distance := float(context.get("unit_distance", 999999.0))
	var target_distance := float(context.get("target_distance", 999999.0))
	var clearance := maxf(0.0, float(context.get("clearance", 0.035)))
	if unit_distance < 0.0:
		return {"before_locked_target": false, "reason": "behind_attacker", "unit_distance": unit_distance, "target_distance": target_distance}
	if unit_distance > target_distance - clearance:
		return {"before_locked_target": false, "reason": "at_or_beyond_locked_target", "unit_distance": unit_distance, "target_distance": target_distance}
	return {"before_locked_target": true, "reason": "before_locked_target", "unit_distance": unit_distance, "target_distance": target_distance}


func gpu_projectile_query_ray_intent(context: Dictionary) -> Dictionary:
	var start := _vec(context.get("start", Vector2.ZERO))
	var end := _vec(context.get("end", start), start)
	var direction := _vec(context.get("direction", Vector2.ZERO))
	var collider_range := start.distance_to(end)
	if direction.length() <= 0.01:
		return {
			"start": start,
			"end": end,
			"direction": direction,
			"range": collider_range,
			"extended": false,
		}
	var reach := maxf(float(context.get("requested_range", collider_range)), collider_range)
	var normalized := direction.normalized()
	return {
		"start": start,
		"end": start + normalized * reach,
		"direction": normalized,
		"range": reach,
		"extended": true,
	}


func gpu_projectile_query_payload(context: Dictionary) -> Dictionary:
	return {
		"start": _vec(context.get("start", Vector2.ZERO)),
		"end": _vec(context.get("end", Vector2.ZERO)),
		"radius": maxf(0.0, float(context.get("radius", 0.0))),
		"owner_unit_key": int(context.get("owner_unit_key", 1)),
		"owner_team_key": int(context.get("owner_team_key", 0)),
		"query_id": int(context.get("query_id", 0)),
		"include_friendly": bool(context.get("include_friendly", false)),
	}


func gpu_projectile_target_entry_payload(context: Dictionary) -> Dictionary:
	var entry := _dict(context.get("entry", {})).duplicate(false)
	entry.erase("unit")
	entry["target_index"] = int(context.get("target_index", -1))
	entry["target_live"] = bool(context.get("target_live", false))
	entry["occluded"] = bool(context.get("occluded", false))
	if bool(context.get("has_target_position", entry["target_live"])):
		entry["target_position"] = _vec(context.get("target_position", Vector2.ZERO))
	return entry


func projectile_candidate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("candidate_live", true)):
		return {"action": "reject", "reason": "candidate_gone"}
	if bool(context.get("true_bullet", false)) and bool(context.get("locked_target_live", false)):
		if bool(context.get("is_locked_target", false)) and bool(context.get("blocked_before_locked", false)):
			return {"action": "reject", "reason": "locked_target_blocked"}
		if not bool(context.get("is_locked_target", false)) and not bool(context.get("candidate_before_locked", false)):
			return {"action": "reject", "reason": "behind_locked_target"}
	var projection := float(context.get("projection", 0.0))
	if projection < -0.001:
		return {"action": "reject", "reason": "negative_projection", "projection": projection}
	return {
		"action": "accept",
		"projection": projection,
	}


func first_impact_selection(candidates: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for raw_candidate in candidates:
		var candidate := _dict(raw_candidate)
		if candidate.is_empty():
			continue
		if String(candidate.get("action", "accept")) == "reject":
			continue
		var distance := float(candidate.get("distance", candidate.get("projection", INF)))
		if distance < 0.0 or distance >= best_distance:
			continue
		best_distance = distance
		best = candidate.duplicate(false)
	if best.is_empty():
		return {}
	best["distance"] = best_distance
	return best


func projectile_selection_result_intent(context: Dictionary) -> Dictionary:
	var selection := _dict(context.get("selection", {}))
	if selection.is_empty():
		return {"action": "reject", "reason": "no_selection"}
	var target_index := int(selection.get("target_index", -1))
	var target_count := maxi(0, int(context.get("target_count", 0)))
	if target_index < 0 or target_index >= target_count:
		return {
			"action": "reject",
			"reason": "invalid_target_index",
			"target_index": target_index,
			"target_count": target_count,
		}
	var intent := {
		"action": "accept",
		"target_index": target_index,
		"hit": _dict(selection.get("hit", {})),
		"distance": float(selection.get("distance", context.get("missing_distance", 999999.0))),
		"has_position": selection.has("position"),
	}
	if bool(intent["has_position"]):
		intent["position"] = _vec(selection.get("position", Vector2.ZERO))
	return intent


func projectile_final_impact_payload(context: Dictionary) -> Dictionary:
	if not bool(context.get("target_live", false)):
		return {"action": "reject", "reason": "target_gone"}
	var selection_result := _dict(context.get("selection_result", {}))
	var position := _vec(context.get("target_position", Vector2.ZERO))
	if bool(selection_result.get("has_position", selection_result.has("position"))):
		position = _vec(selection_result.get("position", position))
	return {
		"action": "accept",
		"hit": _dict(selection_result.get("hit", {})),
		"position": position,
		"distance": float(selection_result.get("distance", context.get("missing_distance", 999999.0))),
	}


func gpu_hit_selection(context: Dictionary) -> Dictionary:
	var hits: Array = Array(context.get("hits", []))
	var entries: Array = Array(context.get("entries", []))
	var attack_collider := _dict(context.get("attack_collider", {}))
	var best: Dictionary = {}
	var best_distance := INF
	for raw_hit in hits:
		var hit_record := _dict(raw_hit)
		if hit_record.is_empty():
			continue
		var collider_index := int(hit_record.get("collider_index", -1))
		if collider_index < 0 or collider_index >= entries.size():
			continue
		var entry := _dict(entries[collider_index])
		if not bool(entry.get("target_live", true)):
			continue
		if bool(entry.get("occluded", false)):
			continue
		var distance := float(hit_record.get("distance", INF))
		if distance >= best_distance:
			continue
		var target_collider := _dict(entry.get("query", entry.get("raw", {})))
		best_distance = distance
		best = {
			"entry_index": collider_index,
			"entry": entry,
			"hit_record": hit_record,
			"hit": _hit_payload({
				"attack_collider": attack_collider,
				"target_collider": target_collider,
				"position": hit_record.get("position", context.get("fallback_position", Vector2.ZERO)),
				"gap": float(context.get("gpu_gap", -0.01)),
				"contact_normal": hit_record.get("normal", Vector2.ZERO),
				"attacker_runtime_topology": true,
				"gpu_query_hit": true,
			}),
			"position": hit_record.get("position", entry.get("target_position", context.get("fallback_position", Vector2.ZERO))),
			"distance": best_distance,
		}
	return best


func gpu_projectile_selection_result_intent(context: Dictionary) -> Dictionary:
	var selection := _dict(context.get("selection", {}))
	if selection.is_empty():
		return {"action": "reject", "reason": "no_selection"}
	var selected_entry := _dict(selection.get("entry", {}))
	var target_index := int(selected_entry.get("target_index", -1))
	var target_count := maxi(0, int(context.get("target_count", 0)))
	if target_index < 0 or target_index >= target_count:
		return {
			"action": "reject",
			"reason": "invalid_target_index",
			"target_index": target_index,
			"target_count": target_count,
		}
	var intent := {
		"action": "accept",
		"target_index": target_index,
		"hit": _dict(selection.get("hit", {})),
		"distance": float(selection.get("distance", context.get("missing_distance", 999999.0))),
		"has_position": selection.has("position"),
	}
	if bool(intent["has_position"]):
		intent["position"] = _vec(selection.get("position", Vector2.ZERO))
	return intent


func gpu_projectile_final_impact_payload(context: Dictionary) -> Dictionary:
	if not bool(context.get("target_live", false)):
		return {"action": "reject", "reason": "target_gone"}
	var selection_result := _dict(context.get("selection_result", {}))
	var position := _vec(context.get("target_position", Vector2.ZERO))
	if bool(selection_result.get("has_position", selection_result.has("position"))):
		position = _vec(selection_result.get("position", position))
	return {
		"action": "accept",
		"hit": _dict(selection_result.get("hit", {})),
		"position": position,
		"distance": float(selection_result.get("distance", context.get("missing_distance", 999999.0))),
	}


func hit_slop_intent(context: Dictionary) -> Dictionary:
	var is_projectile := bool(context.get("projectile", false))
	var direct_runtime_hit := bool(context.get("direct_runtime_hit", false))
	var hit_slop := 0.0 if is_projectile else 0.16
	if direct_runtime_hit:
		hit_slop = 0.0 if is_projectile else -absf(float(context.get("runtime_required_overlap", 0.0)))
	if is_projectile:
		if direct_runtime_hit:
			hit_slop = 0.0
		else:
			var projectile_style := String(context.get("projectile_style", ""))
			var damage_type := String(context.get("projectile_damage_type", context.get("damage_type", "")))
			var width_factor := 0.22 if damage_type == "chemical" or projectile_style == "spray" else 0.08
			hit_slop = maxf(hit_slop, float(context.get("lane_range", 0.0)) * width_factor)
	return {
		"hit_slop": hit_slop,
		"direct_runtime_hit": direct_runtime_hit,
		"projectile": is_projectile,
	}


func part_hit_candidate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("target_collider_valid", true)):
		return {"action": "reject", "reason": "invalid_target_collider"}
	if bool(context.get("projectile", false)) and bool(context.get("has_direction", false)):
		var attack_direction := _vec(context.get("direction", Vector2.ZERO))
		var to_part := _vec(context.get("to_part", Vector2.ZERO))
		if attack_direction.length() > 0.01 and to_part.length() > 0.001:
			var dot := attack_direction.normalized().dot(to_part.normalized())
			if dot < float(context.get("direction_dot_min", 0.02)):
				return {"action": "reject", "reason": "behind_projectile", "direction_dot": dot}
	var gap := float(context.get("gap", INF))
	var hit_slop := float(context.get("hit_slop", 0.0))
	var best_gap := float(context.get("best_gap", INF))
	if gap > hit_slop:
		return {"action": "reject", "reason": "outside_slop", "gap": gap}
	if gap >= best_gap:
		return {"action": "reject", "reason": "not_best", "gap": gap}
	return {
		"action": "accept",
		"gap": gap,
	}


func part_hit_payload(context: Dictionary) -> Dictionary:
	return _hit_payload(context)


func _hit_payload(context: Dictionary) -> Dictionary:
	var attack_collider := _dict(context.get("attack_collider", {}))
	var target_collider := _dict(context.get("target_collider", {}))
	if attack_collider.is_empty() or target_collider.is_empty():
		return {}
	var contact_normal := _vec(context.get("contact_normal", Vector2.ZERO))
	var fallback_direction := _vec(context.get("fallback_direction", Vector2.RIGHT))
	if contact_normal.length() <= 0.001:
		contact_normal = fallback_direction
	if contact_normal.length() <= 0.001:
		contact_normal = Vector2.RIGHT
	contact_normal = contact_normal.normalized()
	return {
		"part_index": int(target_collider.get("part_index", -1)),
		"part_kind": String(target_collider.get("part_kind", "core")),
		"part_name": String(target_collider.get("name", "CORE")),
		"torso_unit_index": int(target_collider.get("torso_unit_index", -1)),
		"target_terminal_weapon_kind": String(target_collider.get("terminal_weapon_kind", "")),
		"attacker_part_kind": String(attack_collider.get("part_kind", "")),
		"attacker_terminal_weapon_kind": String(attack_collider.get("terminal_weapon_kind", "")),
		"attacker_runtime_topology": bool(context.get("attacker_runtime_topology", attack_collider.get("runtime_topology", false))),
		"position": context.get("position", Vector2.ZERO),
		"gap": float(context.get("gap", 0.0)),
		"attacker_collider": attack_collider.duplicate(true),
		"target_collider": target_collider.duplicate(true),
		"contact_normal": contact_normal,
		"gpu_query_hit": bool(context.get("gpu_query_hit", false)),
	}


func _dict(value) -> Dictionary:
	return value if value is Dictionary else {}


func _vec(value, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	return value if value is Vector2 else fallback
