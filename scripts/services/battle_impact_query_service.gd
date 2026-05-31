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
