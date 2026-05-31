extends RefCounted
class_name BattleIdentityRuntimeService


func role_switch_gate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("unit_live", false)):
		return {"accepted": false, "reason": "unit_gone"}
	if bool(context.get("identity_active", false)) or bool(context.get("transfering", false)):
		return {"accepted": false, "reason": "identity_busy"}
	var switch_timer := maxf(0.0, float(context.get("switch_timer", 0.0)))
	if switch_timer > 0.0:
		return {"accepted": false, "reason": "cooldown", "timer": switch_timer}
	if String(context.get("target_role", "")) == "":
		return {"accepted": false, "reason": "no_target_role"}
	if context.has("plan_found") and not bool(context.get("plan_found", false)):
		return {"accepted": false, "reason": "no_target_unit"}
	return {"accepted": true, "reason": "accepted"}


func soul_cast_gate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("unit_live", false)):
		return {"accepted": false, "reason": "unit_gone"}
	if bool(context.get("identity_active", false)) or bool(context.get("transfering", false)):
		return {"accepted": false, "reason": "identity_busy"}
	if String(context.get("role", "")) != "hero":
		return {"accepted": false, "reason": "not_hero"}
	var switch_timer := maxf(0.0, float(context.get("switch_timer", 0.0)))
	if switch_timer > 0.0:
		return {"accepted": false, "reason": "cooldown", "timer": switch_timer}
	if context.has("target_found") and not bool(context.get("target_found", false)):
		return {"accepted": false, "reason": "no_receiver"}
	return {"accepted": true, "reason": "accepted"}


func identity_receiver_selection(candidates: Array, receiver_role: String, receiver_order: int) -> Dictionary:
	if candidates.is_empty():
		return {"found": false, "candidate_index": -1}
	if receiver_role == "any":
		return _nearest_candidate(candidates)
	if receiver_role == "hero" or receiver_role == "barrier":
		for i in range(candidates.size()):
			var candidate := _dict(candidates[i])
			if bool(candidate.get("live", true)) and String(candidate.get("role", "")) == receiver_role:
				return {"found": true, "candidate_index": int(candidate.get("candidate_index", i)), "distance": float(candidate.get("distance", 0.0))}
		return {"found": false, "candidate_index": -1}
	if receiver_role == "puppet":
		var receivers: Array = []
		for i in range(candidates.size()):
			var candidate := _dict(candidates[i])
			if bool(candidate.get("live", true)) and String(candidate.get("role", "")) == "puppet":
				receivers.append({"candidate_index": int(candidate.get("candidate_index", i)), "order": int(candidate.get("order", receivers.size()))})
		if receivers.is_empty():
			return {"found": false, "candidate_index": -1}
		receivers.sort_custom(func(a, b): return int(a.get("order", 0)) < int(b.get("order", 0)))
		var selected: Dictionary = receivers[clampi(receiver_order, 0, receivers.size() - 1)]
		return {"found": true, "candidate_index": int(selected.get("candidate_index", -1))}
	return {"found": false, "candidate_index": -1}


func role_switch_target_selection(candidates: Array, target_role: String) -> Dictionary:
	if target_role == "puppet":
		return _nearest_candidate(candidates, "puppet")
	for i in range(candidates.size()):
		var candidate := _dict(candidates[i])
		if bool(candidate.get("live", true)) and String(candidate.get("role", "")) == target_role:
			return {"found": true, "candidate_index": int(candidate.get("candidate_index", i)), "distance": float(candidate.get("distance", 0.0))}
	return {"found": false, "candidate_index": -1}


func identity_transfer_plan(context: Dictionary) -> Dictionary:
	var kind := String(context.get("kind", "role_switch"))
	var source_role := String(context.get("source_role", ""))
	var target_old_role := String(context.get("target_old_role", ""))
	if kind == "soul_cast":
		if source_role != "hero" or target_old_role == "":
			return {"accepted": false, "reason": "invalid_soul_cast", "plan": {}}
		return {
			"accepted": true,
			"plan": {
				"source_old_role": "hero",
				"target_old_role": target_old_role,
				"source_new_role": target_old_role,
				"target_new_role": "hero",
			},
		}
	var target_role := String(context.get("target_role", ""))
	var role_order: Array = Array(context.get("role_order", []))
	if source_role == "" or target_role == "" or source_role == target_role:
		return {"accepted": false, "reason": "invalid_roles", "plan": {}}
	if not role_order.is_empty() and not role_order.has(target_role):
		return {"accepted": false, "reason": "invalid_target_role", "plan": {}}
	return {
		"accepted": true,
		"plan": {
			"source_old_role": source_role,
			"target_old_role": target_old_role,
			"source_new_role": target_role,
			"target_new_role": source_role,
		},
	}


func role_form_target(stats: Dictionary, current_role: String, role_order: Array) -> String:
	var target := String(stats.get("role_form_target_role", ""))
	if target == "cycle_mech_barrier" or target == "":
		if current_role == "barrier":
			return String(stats.get("role_form_mech_role", "puppet"))
		return "barrier"
	if role_order.has(target):
		return target
	return ""


func role_form_gate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("unit_live", false)):
		return {"accepted": false, "reason": "unit_gone"}
	var switch_timer := maxf(0.0, float(context.get("switch_timer", 0.0)))
	if switch_timer > 0.0:
		return {"accepted": false, "reason": "cooldown", "timer": switch_timer}
	var target_role := String(context.get("target_role", ""))
	var current_role := String(context.get("current_role", ""))
	if target_role == "" or target_role == current_role:
		return {"accepted": false, "reason": "invalid_target"}
	if target_role == "hero" and bool(context.get("hero_occupied", false)):
		return {"accepted": false, "reason": "role_occupied", "role": "hero"}
	if target_role == "barrier" and bool(context.get("barrier_occupied", false)):
		return {"accepted": false, "reason": "role_occupied", "role": "barrier"}
	if target_role == "puppet" and current_role != "puppet" and bool(context.get("other_puppet_live", false)):
		return {"accepted": false, "reason": "role_occupied", "role": "puppet"}
	return {"accepted": true, "reason": "accepted"}


func role_form_finish_intent(context: Dictionary) -> Dictionary:
	var stats := _dict(context.get("stats", {}))
	var target_role := String(context.get("target_role", ""))
	var shape_hint := String(stats.get("role_form_shape", ""))
	var shape := ""
	if shape_hint != "":
		shape = shape_hint
	elif target_role == "barrier":
		shape = "barrier"
	elif target_role == "puppet":
		shape = String(context.get("puppet_shape", ""))
	return {
		"target_role": target_role,
		"shape": shape,
		"switch_timer": maxf(0.0, float(context.get("switch_cooldown", 0.0))),
	}


func morph_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("unit_live", false)):
		return {"accepted": false, "reason": "unit_gone"}
	var timer := maxf(0.0, float(context.get("timer", 0.0)))
	if timer > 0.0:
		return {"accepted": false, "reason": "cooldown", "timer": timer}
	var modes: Array = Array(context.get("modes", ["combat", "travel"]))
	if modes.is_empty():
		modes = ["combat", "travel"]
	var index := (int(context.get("index", 0)) + 1) % modes.size()
	var mode := String(modes[index])
	var current_shape := String(context.get("current_shape", "core"))
	return {
		"accepted": true,
		"index": index,
		"mode": mode,
		"modes": modes,
		"timer": float(context.get("cooldown", 2.6)),
		"shape": morph_shape_for_mode(current_shape, mode),
	}


func morph_shape_for_mode(current_shape: String, mode: String) -> String:
	match mode:
		"travel":
			return "snake"
		"siege":
			return "tank"
		"combat":
			return "crab" if current_shape in ["snake", "tank", "core"] else current_shape
	return current_shape


func combine_partner_selection(candidates: Array, required: int, max_count: int, range_value: float) -> Dictionary:
	var required_count := maxi(1, required)
	var limit := maxi(required_count, max_count)
	var eligible: Array = []
	for i in range(candidates.size()):
		var candidate := _dict(candidates[i])
		if not bool(candidate.get("live", true)):
			continue
		if not bool(candidate.get("can_combine", true)):
			continue
		if bool(candidate.get("combined", false)):
			continue
		if context_candidate_in_range(candidate, range_value):
			eligible.append({
				"candidate_index": int(candidate.get("candidate_index", i)),
				"distance": float(candidate.get("distance", 0.0)),
			})
	eligible.sort_custom(func(a, b): return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0)))
	var selected: Array = []
	for item in eligible:
		if selected.size() >= limit:
			break
		selected.append(int(Dictionary(item).get("candidate_index", -1)))
	return {
		"accepted": selected.size() >= required_count,
		"selected_indices": selected,
		"required": required_count,
		"max_count": limit,
		"available": eligible.size(),
		"reason": "accepted" if selected.size() >= required_count else "insufficient_partners",
	}


func combine_intent(context: Dictionary) -> Dictionary:
	var stats := _dict(context.get("stats", {}))
	var updated_stats := stats.duplicate(true)
	var partner_snapshots: Array = Array(context.get("partner_snapshots", []))
	var total_partner_health := 0
	var total_partner_radius := 0.0
	var total_partner_length := 0.0
	for raw_snapshot in partner_snapshots:
		var snapshot := _dict(raw_snapshot)
		var partner_stats := _dict(snapshot.get("stats", {}))
		total_partner_health += int(snapshot.get("health", 0))
		total_partner_radius += float(partner_stats.get("radius", 0.2))
		total_partner_length += float(partner_stats.get("length", 0.4))
	var shape := String(stats.get("combine_shape", "tank")) if String(stats.get("combine_shape", "")) != "" else "tank"
	updated_stats["shape"] = shape
	updated_stats["radius"] = float(stats.get("radius", 0.3)) + total_partner_radius * 0.72
	updated_stats["length"] = minf(4.5, float(stats.get("length", 1.0)) + total_partner_length * 0.64)
	var max_health := int(context.get("max_health", 1)) + total_partner_health + int(stats.get("combine_bonus_hp", 24))
	var health := mini(max_health, int(context.get("health", 1)) + total_partner_health)
	return {
		"accepted": true,
		"stats": updated_stats,
		"max_health": max_health,
		"health": health,
		"partner_count": partner_snapshots.size(),
		"combine_store": {
			"stats": stats.duplicate(true),
			"max_health": int(context.get("max_health", 1)),
			"partners": partner_snapshots.duplicate(true),
		},
	}


func separate_intent(context: Dictionary) -> Dictionary:
	var store := _dict(context.get("store", {}))
	var restored_stats := _dict(store.get("stats", context.get("fallback_stats", {})))
	var max_health := int(store.get("max_health", context.get("max_health", 1)))
	return {
		"accepted": true,
		"stats": restored_stats,
		"max_health": max_health,
		"health": mini(int(context.get("health", max_health)), max_health),
		"partner_snapshots": Array(store.get("partners", [])),
	}


func separated_partner_spawn_intent(context: Dictionary) -> Dictionary:
	var snapshot := _dict(context.get("snapshot", {}))
	var stats := _dict(snapshot.get("stats", {}))
	if stats.is_empty():
		return {"spawn": false, "reason": "empty_stats"}
	var role_key := String(snapshot.get("role", "puppet"))
	if role_key == "hero" and bool(context.get("hero_occupied", false)):
		role_key = "puppet"
	if role_key == "barrier" and bool(context.get("barrier_occupied", false)):
		role_key = "puppet"
	var index := int(context.get("index", 0))
	var count := int(context.get("count", 1))
	var angle := TAU * float(index + 1) / float(maxi(2, count + 1))
	var ring_length := maxf(0.001, float(context.get("ring_length", 1.0)))
	var half_height := maxf(0.001, float(context.get("battle_half_height", 1.0)))
	var spawn_ring := wrapf(float(context.get("lead_ring", 0.0)) + cos(angle) * 0.32, 0.0, ring_length)
	var spawn_lane := clampf(float(context.get("lead_lane", 0.0)) + sin(angle) * 0.28, -half_height, half_height)
	var max_health := int(snapshot.get("max_health", 1))
	return {
		"spawn": true,
		"role": role_key,
		"stats": stats,
		"name": String(snapshot.get("name", "P%d SEPARATED" % int(context.get("owner", 1)))),
		"ring": spawn_ring,
		"lane": spawn_lane,
		"max_health": max_health,
		"health": clampi(int(snapshot.get("health", max_health)), 1, max_health),
	}


func context_candidate_in_range(candidate: Dictionary, range_value: float) -> bool:
	if candidate.has("within_range"):
		return bool(candidate.get("within_range", false))
	var range_x := maxf(0.0, range_value)
	var range_y := range_x * 0.72
	return absf(float(candidate.get("delta_x", 0.0))) <= range_x and absf(float(candidate.get("delta_y", 0.0))) <= range_y


func _nearest_candidate(candidates: Array, role_filter: String = "") -> Dictionary:
	var best_index := -1
	var best_distance := INF
	for i in range(candidates.size()):
		var candidate := _dict(candidates[i])
		if not bool(candidate.get("live", true)):
			continue
		if role_filter != "" and String(candidate.get("role", "")) != role_filter:
			continue
		var distance := float(candidate.get("distance", 0.0))
		if distance < best_distance:
			best_distance = distance
			best_index = int(candidate.get("candidate_index", i))
	if best_index < 0:
		return {"found": false, "candidate_index": -1}
	return {"found": true, "candidate_index": best_index, "distance": best_distance}


func _dict(value) -> Dictionary:
	if value is Dictionary:
		return value
	return {}
