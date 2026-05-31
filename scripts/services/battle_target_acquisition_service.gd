extends RefCounted
class_name BattleTargetAcquisitionService

const DEFAULT_TARGET_CLASSES := ["hero", "puppet", "barrier_support", "barrier_attack", "barrier_other"]


func normalized_target_direction(context: Dictionary) -> Dictionary:
	var fallback := _vec(context.get("fallback_direction", Vector2.RIGHT))
	if fallback.length() <= 0.01:
		fallback = Vector2.RIGHT
	var delta := _vec(context.get("delta", Vector2.ZERO))
	if bool(context.get("target_live", false)) and delta.length() > 0.01:
		return {"direction": delta.normalized(), "reason": "delta"}
	return {"direction": fallback.normalized(), "reason": "fallback"}


func target_class(snapshot: Dictionary) -> String:
	if not bool(snapshot.get("live", true)):
		return ""
	var role_key := String(snapshot.get("role", ""))
	if role_key == "hero" or role_key == "puppet":
		return role_key
	if role_key != "barrier":
		return "barrier_other"
	var stats := _dict(snapshot.get("stats", {}))
	if bool(stats.get("is_repair_station", false)) or bool(stats.get("is_coolant_field", false)) or bool(stats.get("is_coin_generator", false)) or bool(stats.get("is_resource_siphon", false)):
		return "barrier_support"
	var support_kind := String(stats.get("support_kind", ""))
	if support_kind in ["ammo", "repair", "cooling", "damage_buff", "armor", "resource"]:
		return "barrier_support"
	if bool(stats.get("is_barrage_emitter", false)) or bool(stats.get("is_trap_field", false)) or bool(stats.get("is_homing_launcher", false)) or bool(stats.get("is_hatchery", false)) or bool(stats.get("is_signal_jammer", false)) or bool(stats.get("is_hack_field", false)) or bool(stats.get("is_cage_wall", false)) or bool(stats.get("reflect_projectiles", false)):
		return "barrier_attack"
	return "barrier_other"


func target_class_allowed(target_class_value: String, allowed_classes: Array) -> bool:
	var classes := allowed_classes
	if classes.is_empty():
		return true
	return classes.has(target_class_value)


func true_bullet_candidate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("candidate_live", true)):
		return {"action": "reject", "reason": "candidate_gone"}
	if not bool(context.get("has_hit", false)):
		return {"action": "reject", "reason": "no_hit"}
	var distance := float(context.get("distance", context.get("projection", 999999.0)))
	if distance < 0.0:
		return {"action": "reject", "reason": "negative_projection", "distance": distance}
	return {
		"action": "accept",
		"target_index": int(context.get("target_index", -1)),
		"distance": distance,
		"position": context.get("position", Vector2.ZERO),
		"hit": _dict(context.get("hit", {})).duplicate(true),
	}


func true_bullet_target_selection(candidates: Array, wrapped_candidate: Dictionary = {}) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for raw_candidate in candidates:
		var candidate := _dict(raw_candidate)
		if candidate.is_empty() or String(candidate.get("action", "accept")) == "reject":
			continue
		var distance := float(candidate.get("distance", INF))
		if distance < 0.0 or distance >= best_distance:
			continue
		best_distance = distance
		best = candidate.duplicate(true)
	if not best.is_empty():
		best["found"] = true
		best["reason"] = "direct"
		best["distance"] = best_distance
		return best
	var wrapped := _dict(wrapped_candidate)
	if wrapped.is_empty() or not bool(wrapped.get("candidate_live", true)):
		return {"found": false, "target_index": -1, "reason": "no_target"}
	var wrapped_distance := float(wrapped.get("distance", INF))
	return {
		"found": true,
		"reason": "wrapped",
		"target_index": int(wrapped.get("target_index", -1)),
		"distance": wrapped_distance,
		"position": wrapped.get("position", Vector2.ZERO),
		"hit": _dict(wrapped.get("hit", {})).duplicate(true),
	}


func missile_candidate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("candidate_live", true)):
		return {"action": "reject", "reason": "candidate_gone"}
	var target_class_value := String(context.get("target_class", ""))
	var allowed_classes: Array = Array(context.get("allowed_classes", DEFAULT_TARGET_CLASSES))
	if not target_class_allowed(target_class_value, allowed_classes):
		return {"action": "reject", "reason": "class_blocked", "target_class": target_class_value}
	var distance := float(context.get("distance", _vec(context.get("delta", Vector2.ZERO)).length()))
	if distance <= 0.001:
		return {"action": "reject", "reason": "too_close", "distance": distance}
	if distance > maxf(0.1, float(context.get("max_range", 0.1))):
		return {"action": "reject", "reason": "out_of_range", "distance": distance}
	var direction := _normalized_or(_vec(context.get("direction", Vector2.RIGHT)), Vector2.RIGHT)
	var target_dir := _normalized_or(_vec(context.get("target_direction", _vec(context.get("delta", Vector2.ZERO)))), direction)
	var cone_cos := float(context.get("cone_cos", -1.0))
	var dot := direction.dot(target_dir)
	if dot < cone_cos:
		return {"action": "reject", "reason": "outside_cone", "dot": dot}
	if bool(context.get("occluded", false)):
		return {"action": "reject", "reason": "occluded"}
	return {
		"action": "accept",
		"target_index": int(context.get("target_index", -1)),
		"target_class": target_class_value,
		"distance": distance,
		"aim_dot": dot,
	}


func missile_lock_score(context: Dictionary) -> float:
	var direction := _normalized_or(_vec(context.get("direction", Vector2.RIGHT)), Vector2.RIGHT)
	var delta := _vec(context.get("delta", Vector2.ZERO))
	var distance := float(context.get("distance", delta.length()))
	var target_dir := _normalized_or(_vec(context.get("target_direction", delta)), direction)
	var aim_error := acos(clampf(direction.dot(target_dir), -1.0, 1.0))
	var priority := String(context.get("priority", "screen_hero_first"))
	if priority == "near_first":
		return distance * 1000.0 + aim_error * 10.0
	if priority == "far_first":
		return -distance * 1000.0 + aim_error * 10.0
	var role_rank := 4.0
	match String(context.get("target_class", "")):
		"hero":
			role_rank = 0.0
		"puppet":
			role_rank = 1.0
		"barrier_support":
			role_rank = 2.0
		"barrier_attack":
			role_rank = 3.0
	var screen_rank := 0.0 if bool(context.get("screen_visible", false)) else 1.0
	return role_rank * 1000000.0 + screen_rank * 100000.0 + aim_error * 1000.0 + distance


func missile_target_selection(candidates: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_score := INF
	for raw_candidate in candidates:
		var candidate := _dict(raw_candidate)
		if candidate.is_empty() or String(candidate.get("action", "accept")) == "reject":
			continue
		var score := float(candidate.get("score", INF))
		if score >= best_score:
			continue
		best_score = score
		best = candidate.duplicate(true)
	if best.is_empty():
		return {"found": false, "target_index": -1, "reason": "no_target"}
	best["found"] = true
	best["score"] = best_score
	return best


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
