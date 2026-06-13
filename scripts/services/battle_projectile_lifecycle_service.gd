extends RefCounted
class_name BattleProjectileLifecycleService


func chemical_projectile_tick_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("attacker_live", false)):
		return {"action": "remove", "reason": "attacker_gone"}
	var timer := float(context.get("timer", 0.0)) - float(context.get("delta", 0.0))
	if timer <= 0.0:
		return {"action": "resolve", "timer": 0.0, "event_patch": {"chemical_projectile_ready": true}}
	return {"action": "update", "timer": timer}


func missile_projectile_tick_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("attacker_live", false)):
		return {"action": "remove", "reason": "attacker_gone"}
	var delta := float(context.get("delta", 0.0))
	var event_patch: Dictionary = {}
	var target_locked := false
	var target_lost := false
	var occluded_for := float(context.get("occluded_for", 0.0))
	var last_direction := _vec(context.get("last_direction", Vector2.ZERO))
	var fallback_direction := _normalized_or(_vec(context.get("fallback_direction", Vector2.RIGHT)), Vector2.RIGHT)
	if bool(context.get("target_live", false)):
		var current_direction := _normalized_or(_vec(context.get("current_direction", last_direction)), fallback_direction)
		if bool(context.get("target_occluded", false)):
			occluded_for += delta
		else:
			occluded_for = 0.0
			last_direction = current_direction
		if occluded_for > float(context.get("occlusion_grace", 0.0)):
			target_lost = true
			event_patch["erase_locked_target"] = true
			event_patch["aim_locked"] = false
		else:
			target_locked = true
	if last_direction.length() <= 0.01:
		last_direction = fallback_direction
	event_patch["direction"] = _normalized_or(last_direction, fallback_direction)
	var timer := float(context.get("timer", 0.0)) - delta
	if timer <= 0.0:
		event_patch["missile_flight_ready"] = true
		event_patch["projectile_trace_spawned"] = true
		return {
			"action": "resolve",
			"timer": 0.0,
			"event_patch": event_patch,
			"occluded_for": occluded_for,
			"last_direction": event_patch["direction"],
			"target_lost": target_lost,
			"target_locked": target_locked,
		}
	return {
		"action": "update",
		"timer": timer,
		"event_patch": event_patch,
		"occluded_for": occluded_for,
		"last_direction": event_patch["direction"],
		"target_lost": target_lost,
		"target_locked": target_locked,
	}


func chemical_firework_pellet_intents(context: Dictionary) -> Array:
	var base_event := _dict(context.get("event", {}))
	var pellets := clampi(int(context.get("pellets", base_event.get("chemical_pellets", 7))), 3, 11)
	var spread := clampf(float(context.get("spread", base_event.get("chemical_spread", 0.54))), 0.12, 1.1)
	var base_direction := _normalized_or(_vec(context.get("base_direction", base_event.get("direction", Vector2.RIGHT))), Vector2.RIGHT)
	var intents: Array = []
	for i in range(pellets):
		var t := 0.0 if pellets <= 1 else float(i) / float(pellets - 1)
		var angle := lerpf(-spread * 0.5, spread * 0.5, t)
		var pellet := base_event.duplicate(true)
		pellet["chemical_firework_expanded"] = true
		pellet["direction"] = base_direction.rotated(angle).normalized()
		pellet["range"] = float(base_event.get("range", 1.0)) * (0.82 + 0.06 * float(i % 3))
		pellet["lane_range"] = maxf(0.04, float(base_event.get("lane_range", 0.2)) * 0.62)
		pellet["damage"] = maxi(1, int(roundf(float(base_event.get("damage", 1)) * 0.46)))
		pellet["travel_path"] = "straight"
		intents.append({"action": "resolve_pellet", "event": pellet})
	return intents


func web_tether_tick_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("attacker_live", false)) or not bool(context.get("target_live", false)):
		return {"action": "remove", "reason": "subject_gone"}
	var delta := float(context.get("delta", 0.0))
	var timer := float(context.get("timer", 0.0)) - delta
	if timer <= 0.0:
		return {"action": "remove", "reason": "expired", "timer": 0.0}
	var delta_vec := _vec(context.get("delta_vec", Vector2.ZERO))
	if delta_vec.length() <= 0.01:
		return {"action": "update", "timer": timer, "attacker_velocity_delta": Vector2.ZERO, "target_velocity_delta": Vector2.ZERO}
	var strength := maxf(0.01, float(context.get("strength", 0.01)))
	var break_force := maxf(0.08, float(context.get("break_force", 0.08)))
	var attacker_mass := maxf(1.0, float(context.get("attacker_mass", 1.0)))
	var target_mass := maxf(1.0, float(context.get("target_mass", 1.0)))
	var tension := strength * (0.72 + delta_vec.length() * 0.55 + absf(attacker_mass - target_mass) / maxf(1.0, attacker_mass + target_mass) * 0.42)
	if tension > break_force:
		return {"action": "snap", "timer": timer, "tension": tension}
	var direction := delta_vec.normalized()
	var accel := strength * float(context.get("accel_mult", 1.0))
	var attacker_delta := Vector2.ZERO
	var target_delta := Vector2.ZERO
	match String(context.get("mode", "mass_duel")):
		"self_to_anchor":
			attacker_delta = direction * accel * delta
		"target_to_self":
			target_delta = -direction * accel * delta
		_:
			var attacker_share := clampf(target_mass / (attacker_mass + target_mass), 0.1, 0.9)
			var target_share := clampf(attacker_mass / (attacker_mass + target_mass), 0.1, 0.9)
			attacker_delta = direction * accel * attacker_share * delta
			target_delta = -direction * accel * target_share * delta
	return {
		"action": "update",
		"timer": timer,
		"tension": tension,
		"attacker_velocity_delta": attacker_delta,
		"target_velocity_delta": target_delta,
	}


func web_swing_tick_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("attacker_live", false)):
		return {"action": "remove", "reason": "attacker_gone"}
	var delta := float(context.get("delta", 0.0))
	var timer := float(context.get("timer", 0.0)) - delta
	if timer <= 0.0:
		return {"action": "remove", "reason": "expired", "timer": 0.0}
	var to_anchor := _vec(context.get("to_anchor", Vector2.ZERO))
	if to_anchor.length() <= 0.03:
		return {"action": "remove", "reason": "at_anchor", "timer": timer}
	var strength := maxf(0.01, float(context.get("strength", 0.01)))
	var break_force := maxf(0.08, float(context.get("break_force", 0.08)))
	var attacker_velocity := _vec(context.get("attacker_velocity", Vector2.ZERO))
	var tension := strength * (0.72 + to_anchor.length() * 0.62 + attacker_velocity.length() * 0.1)
	if tension > break_force:
		return {"action": "snap", "timer": timer, "tension": tension}
	var radial := to_anchor.normalized()
	var tangent := Vector2(-radial.y, radial.x)
	var forward := _normalized_or(_vec(context.get("forward", Vector2.RIGHT)), Vector2.RIGHT)
	if tangent.dot(forward) < 0.0:
		tangent = -tangent
	var accel := strength * float(context.get("accel_mult", 1.0))
	return {
		"action": "update",
		"timer": timer,
		"tension": tension,
		"attacker_velocity_delta": (radial * accel + tangent * accel * 0.42) * delta,
	}


func web_target_candidate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("attacker_live", false)):
		return {"include": false, "reason": "attacker_gone"}
	if not bool(context.get("target_live", false)):
		return {"include": false, "reason": "target_gone"}
	if bool(context.get("is_self", false)):
		return {"include": false, "reason": "self"}
	return {"include": true}


func web_impact_candidate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("has_hit", false)):
		return {"include": false, "reason": "no_hit"}
	var projection := float(context.get("projection", INF))
	if projection < -0.001:
		return {"include": false, "reason": "behind"}
	return {
		"include": true,
		"candidate_index": int(context.get("candidate_index", -1)),
		"target_index": int(context.get("target_index", -1)),
		"distance": projection,
		"position": _vec(context.get("position", Vector2.ZERO)),
	}


func web_impact_selection(candidates: Array) -> Dictionary:
	var best_index := -1
	var best_target_index := -1
	var best_distance := INF
	for candidate_value in candidates:
		var candidate := _dict(candidate_value)
		if not bool(candidate.get("include", true)):
			continue
		var distance := float(candidate.get("distance", INF))
		if distance < best_distance:
			best_distance = distance
			best_index = int(candidate.get("candidate_index", -1))
			best_target_index = int(candidate.get("target_index", -1))
	if best_index < 0:
		return {"has_hit": false}
	return {
		"has_hit": true,
		"candidate_index": best_index,
		"target_index": best_target_index,
		"distance": best_distance,
	}


func web_boundary_anchor_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("attacker_live", false)):
		return {"action": "none", "reason": "attacker_gone"}
	if not bool(context.get("anchor_enabled", true)):
		return {"action": "none", "reason": "disabled"}
	var direction := _vec(context.get("direction", Vector2.ZERO))
	if direction.length() <= 0.01:
		return {"action": "none", "reason": "no_direction"}
	direction = direction.normalized()
	if absf(direction.y) <= 0.01:
		return {"action": "none", "reason": "horizontal"}
	var start := _vec(context.get("attacker_position", Vector2.ZERO))
	var half_height := maxf(0.001, float(context.get("half_height", 1.0)))
	var boundary_y := half_height if direction.y > 0.0 else -half_height
	var distance := (boundary_y - start.y) / direction.y
	if distance <= 0.0:
		return {"action": "none", "reason": "behind"}
	var max_range := maxf(0.1, float(context.get("range", context.get("projectile_range", 1.0))))
	if distance > max_range:
		return {"action": "none", "reason": "out_of_range", "distance": distance}
	var ring_length := maxf(0.001, float(context.get("ring_length", 1.0)))
	var anchor := Vector2(wrapf(start.x + direction.x * distance, 0.0, ring_length), boundary_y)
	return {
		"action": "anchor",
		"position": anchor,
		"distance": distance,
		"boundary": "top" if boundary_y > 0.0 else "bottom",
	}


func web_fire_intent(context: Dictionary) -> Dictionary:
	if bool(context.get("target_hit", false)):
		return {"action": "target_tether"}
	if bool(context.get("boundary_anchor", false)):
		return {"action": "boundary_swing", "anchor": context.get("anchor_position", Vector2.ZERO)}
	var direction := _normalized_or(_vec(context.get("direction", context.get("fallback_direction", Vector2.RIGHT))), _vec(context.get("fallback_direction", Vector2.RIGHT)))
	var attacker_position := _vec(context.get("attacker_position", Vector2.ZERO))
	var fire_range := float(context.get("range", 1.0))
	var ring_length := maxf(0.001, float(context.get("ring_length", 1.0)))
	var half_height := maxf(0.001, float(context.get("half_height", 1.0)))
	return {
		"action": "miss_trace",
		"miss_position": Vector2(
			wrapf(attacker_position.x + direction.x * fire_range, 0.0, ring_length),
			clampf(attacker_position.y + direction.y * fire_range, -half_height, half_height)
		),
	}


func explosion_request_intent(context: Dictionary) -> Dictionary:
	var event := _dict(context.get("event", {}))
	var damage := int(event.get("explosion_damage", 0))
	if damage <= 0:
		return {"applies": false, "reason": "no_damage"}
	return {
		"applies": true,
		"reason": "ok",
		"radius": maxf(0.08, float(event.get("explosion_radius", 0.0))),
		"damage": damage,
		"damage_type": String(event.get("explosion_damage_type", event.get("damage_type", "blunt"))),
		"explosion_style": String(event.get("explosion_style", "explosive")),
	}


func explosion_center_position(context: Dictionary) -> Dictionary:
	var attacker_position := _vec(context.get("attacker_position", Vector2.ZERO))
	if bool(context.get("primary_target_valid", false)):
		return {
			"position": _vec(context.get("primary_target_position", attacker_position)),
			"source": "primary_target",
		}
	return {
		"position": attacker_position,
		"source": "attacker",
	}


func explosion_initial_effect_anchor_intent(context: Dictionary) -> Dictionary:
	if bool(context.get("primary_target_valid", false)):
		return {"source": "primary_target"}
	return {"source": "attacker"}


func explosion_target_candidate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("target_live", false)):
		return {"include": false, "reason": "target_gone"}
	if bool(context.get("is_primary_target", false)):
		return {"include": false, "reason": "primary_target"}
	return {"include": true, "reason": "ok"}


func explosion_damage_intent(context: Dictionary) -> Dictionary:
	var radius := maxf(0.08, float(context.get("radius", 0.0)))
	var target_radius := maxf(0.0, float(context.get("target_radius", 0.0)))
	var blast_delta := _vec(context.get("blast_delta", Vector2.ZERO))
	var distance := absf(blast_delta.x)
	var lane_distance := absf(blast_delta.y)
	if distance > radius + target_radius or lane_distance > radius * 0.72 + target_radius * 0.6:
		return {"applies": false}
	var falloff := clampf(1.0 - (distance + lane_distance * 0.7) / maxf(0.1, radius * 1.6), 0.35, 1.0)
	var direction := blast_delta
	if direction.length() <= 0.001:
		direction = _vec(context.get("fallback_direction", Vector2.RIGHT))
	direction = _normalized_or(direction, Vector2.RIGHT)
	var momentum := maxf(0.0, float(context.get("projectile_momentum", 0.0))) * falloff
	var damage_type := String(context.get("damage_type", "blunt"))
	var style := String(context.get("explosion_style", "explosive"))
	return {
		"applies": true,
		"falloff": falloff,
		"blast_direction": direction,
		"blast_momentum": momentum,
		"event_patch": {
			"damage_type": damage_type,
			"projectile": false,
			"hit_position_combat": context.get("target_position", Vector2.ZERO),
		},
		"stagger_patch": {
			"projectile": true,
			"projectile_behavior": "explosive",
			"projectile_style": style,
		},
	}


func projectile_hit_block_intent(context: Dictionary) -> Dictionary:
	if int(context.get("final_damage", 0)) <= 0:
		return {"blocked": true, "reason": "no_damage"}
	if bool(context.get("contact_gate_blocked", false)):
		return {"blocked": true, "reason": "contact_gate_blocked"}
	return {"blocked": false, "reason": "ok"}


func projectile_reflector_candidate_intent(context: Dictionary) -> Dictionary:
	if bool(context.get("is_self", false)):
		return {"include": false, "reason": "self"}
	if not bool(context.get("reflector_live", false)):
		return {"include": false, "reason": "reflector_gone"}
	if not bool(context.get("reflect_projectiles", false)):
		return {"include": false, "reason": "reflection_disabled"}
	var reflect_types: Array = Array(context.get("reflect_types", []))
	if not reflect_types.is_empty() and not reflect_types.has(String(context.get("damage_type", "bullet"))):
		return {"include": false, "reason": "damage_type_rejected"}
	return {"include": true, "reason": "ok"}


func projectile_reflection_intent(context: Dictionary) -> Dictionary:
	var direction := _vec(context.get("direction", Vector2.ZERO))
	if direction.length() <= 0.01:
		return {"action": "none", "reason": "no_direction"}
	direction = direction.normalized()
	var candidates: Array = Array(context.get("candidates", []))
	var best_index := -1
	var best_score := INF
	var fire_range := float(context.get("range", 1.0))
	for i in range(candidates.size()):
		var candidate := _dict(candidates[i])
		if not bool(candidate.get("valid", true)):
			continue
		var delta_vec := _vec(candidate.get("delta_vec", Vector2.ZERO))
		var distance := float(candidate.get("distance", delta_vec.length()))
		if distance <= 0.01 or distance > fire_range + float(candidate.get("radius", 0.2)):
			continue
		var angle_score := 1.0 - direction.dot(delta_vec.normalized())
		var lane_score := absf(float(candidate.get("lane_delta", 0.0))) * 0.35
		var score := angle_score + lane_score + distance * 0.08
		if score < best_score:
			best_score = score
			best_index = i
	if best_index < 0:
		return {"action": "none", "reason": "no_reflector"}
	var best := _dict(candidates[best_index])
	var lane_delta := float(best.get("lane_delta", 0.0))
	var normal := Vector2(0.0, -1.0 if lane_delta < 0.0 else 1.0)
	if absf(lane_delta) < 0.08:
		normal = Vector2(-float(context.get("attacker_facing", 1.0)), 0.0)
	var reflected := direction.bounce(normal).normalized()
	var needs_fallback := reflected.length() <= 0.01
	if needs_fallback:
		reflected = _vec(context.get("fallback_direction", Vector2.ZERO))
	return {
		"action": "reflect",
		"candidate_index": best_index,
		"score": best_score,
		"direction": reflected,
		"needs_fallback": needs_fallback,
		"event_patch": {
			"range": fire_range + float(best.get("reflect_bonus_range", 0.35)),
			"lane_range": float(context.get("lane_range", 0.2)) + float(best.get("reflect_power", 0.25)) * 0.18,
			"reflections": int(context.get("reflections", 0)) + 1,
		},
	}


func target_projectile_shield_reflects(context: Dictionary) -> bool:
	if not bool(context.get("target_live", false)):
		return false
	if float(context.get("shield_timer", 0.0)) <= 0.0:
		return false
	var reflect_types: Array = Array(context.get("reflect_types", []))
	return reflect_types.is_empty() or reflect_types.has(String(context.get("damage_type", "bullet")))


func target_shield_reflection_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("target_live", false)):
		return {"action": "none", "reason": "target_gone"}
	var event := _dict(context.get("event", {}))
	var power := maxf(0.1, float(context.get("power", 0.55)))
	var fallback_direction := _normalized_or(_vec(context.get("fallback_direction", Vector2.RIGHT)), Vector2.RIGHT)
	var attacker_delta := _vec(context.get("attacker_delta", Vector2.ZERO))
	var reflected_direction := attacker_delta.normalized() if attacker_delta.length() > 0.01 else fallback_direction
	return {
		"action": "reflect",
		"direction": reflected_direction,
		"damage_type": String(event.get("damage_type", "bullet")),
		"event_patch": {
			"owner_id": int(context.get("owner_id", 0)),
			"source_name": String(context.get("source_name", "shield")),
			"range": float(event.get("range", 1.0)) + float(context.get("bonus_range", 0.4)),
			"lane_range": float(event.get("lane_range", 0.2)) + power * 0.16,
			"damage": maxi(1, int(roundf(float(event.get("damage", 1)) * (0.58 + power * 0.34)))),
			"direction": reflected_direction,
		},
	}


func target_shield_reflected_target_intent(context: Dictionary) -> Dictionary:
	if bool(context.get("is_attacker", false)):
		return {"include": false, "reason": "attacker"}
	if bool(context.get("is_source_target", false)):
		return {"include": false, "reason": "source_target"}
	if not bool(context.get("reflected_target_live", false)):
		return {"include": false, "reason": "target_gone"}
	var reflected_delta := _vec(context.get("reflected_delta", Vector2.ZERO))
	var distance := absf(reflected_delta.x)
	var lane_distance := absf(reflected_delta.y)
	var target_radius := maxf(0.0, float(context.get("target_radius", 0.0)))
	var range := float(context.get("range", 1.0))
	var lane_range := float(context.get("lane_range", 0.2))
	if distance > range + target_radius:
		return {"include": false, "reason": "out_of_range", "distance": distance, "lane_distance": lane_distance}
	if lane_distance > lane_range + target_radius * 0.6:
		return {"include": false, "reason": "out_of_lane", "distance": distance, "lane_distance": lane_distance}
	var reflected_direction := _normalized_or(_vec(context.get("reflected_direction", Vector2.RIGHT)), Vector2.RIGHT)
	if reflected_delta.length() > 0.01 and reflected_direction.dot(reflected_delta.normalized()) < 0.24:
		return {"include": false, "reason": "direction_rejected", "distance": distance, "lane_distance": lane_distance}
	return {"include": true, "reason": "ok", "distance": distance, "lane_distance": lane_distance}


func projectile_source_node_for_event(event: Dictionary, fallback: int = 0) -> int:
	return int(event.get("source_gun_node", event.get("source_node_index", event.get("muscle_node", fallback))))


func projectile_event_has_gun_source(event: Dictionary) -> bool:
	if not bool(event.get("projectile", false)):
		return true
	if not event.has("muscle_node") or not event.has("collision_group"):
		return false
	var group_raw = event.get("collision_group", {})
	if not (group_raw is Dictionary):
		return false
	var group: Dictionary = group_raw
	if not bool(group.get("projectile", false)) and not bool(group.get("projectile_only", false)):
		return false
	var material_class := String(group.get("material_class", "")).to_lower()
	if material_class in ["gun", "missile_launcher", "web_gun"]:
		return true
	var shape := String(group.get("shape", "")).to_lower()
	return shape in ["gun", "rifle", "turret", "heavy_cannon", "mortar", "missile_rack", "web_gun"]


func runtime_melee_projectile_clear_intent(_event: Dictionary = {}) -> Dictionary:
	return {
		"set": {
			"projectile": false,
			"projectile_only": false,
			"runtime_melee_contact": true,
		},
		"erase": ["projectile_style", "projectile_behavior", "travel_path", "projectile_damage_type"],
	}


func runtime_gun_pose_clear_node(payload: Dictionary, fallback: int = -1) -> int:
	if payload.has("source_gun_node") or payload.has("source_node_index") or payload.has("muscle_node"):
		return projectile_source_node_for_event(payload, fallback)
	if payload.get("binding", {}) is Dictionary:
		var binding: Dictionary = payload.get("binding", {})
		var target_nodes: Array = Array(binding.get("target_nodes", []))
		if not target_nodes.is_empty():
			return int(target_nodes[target_nodes.size() - 1])
	var direct_nodes: Array = Array(payload.get("target_nodes", []))
	if not direct_nodes.is_empty():
		return int(direct_nodes[direct_nodes.size() - 1])
	return fallback


func group_uses_true_bullet(group: Dictionary, behavior: String) -> bool:
	return bool(group.get("projectile", false)) and behavior == "true_bullet"


func true_bullet_event_pending(event: Dictionary, behavior: String) -> bool:
	if bool(event.get("true_bullet_ready", false)):
		return false
	if bool(event.get("non_damage", false)):
		return false
	if not bool(event.get("projectile", false)):
		return false
	return behavior == "true_bullet"


func true_bullet_event_fired(event: Dictionary, behavior: String) -> bool:
	return bool(event.get("projectile", false)) and bool(event.get("true_bullet_ready", false)) and behavior == "true_bullet"


func _dict(value) -> Dictionary:
	return value if value is Dictionary else {}


func _vec(value, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	return value if value is Vector2 else fallback


func _normalized_or(value: Vector2, fallback: Vector2) -> Vector2:
	if value.length() > 0.01:
		return value.normalized()
	if fallback.length() > 0.01:
		return fallback.normalized()
	return Vector2.RIGHT
