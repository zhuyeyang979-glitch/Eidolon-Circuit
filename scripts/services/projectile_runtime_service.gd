extends RefCounted
class_name ProjectileRuntimeService


func projectile_style_for_damage(damage_type: String) -> String:
	match damage_type:
		"chemical":
			return "spray"
		"laser":
			return "beam"
		"bullet":
			return "bullet"
	return "thrown"


func projectile_behavior_for_data(data: Dictionary) -> String:
	var behavior := String(data.get("projectile_behavior", ""))
	if behavior != "":
		return behavior
	var damage_type := String(data.get("projectile_damage_type", data.get("damage_type", "")))
	var style := String(data.get("projectile_style", ""))
	var path := String(data.get("travel_path", ""))
	if style in ["web", "web_snap"] or path == "tether":
		return "web_tether"
	if style in ["explosive", "blast"] or (style == "missile" and float(data.get("explosion_radius", 0.0)) > 0.0):
		return "explosive"
	if damage_type == "bullet":
		if style in ["true_bullet", "rail"]:
			return "true_bullet"
		if style in ["", "bullet", "bullet_hell"]:
			return "bullet_hell"
	if damage_type == "chemical":
		return "chemical_firework" if path in ["firework", "shotgun", "burst", "sine", "arc_u"] else "chemical_line"
	return ""


func projectile_behavior_key(event: Dictionary) -> String:
	var behavior := projectile_behavior_for_data(event)
	var style := String(event.get("projectile_style", ""))
	var damage_type := String(event.get("damage_type", event.get("projectile_damage_type", "bullet")))
	if behavior == "web_tether" or style in ["web", "web_snap"] or String(event.get("travel_path", "")) == "tether":
		return "web_tether"
	if behavior == "true_bullet" or style == "true_bullet":
		return "true_bullet"
	if behavior == "explosive" or style in ["explosive", "blast", "missile"]:
		return "explosive"
	if behavior == "bullet_hell" or style == "bullet_hell":
		return "bullet_hell"
	if damage_type == "laser" or style in ["beam", "chaos"]:
		return "laser"
	if damage_type == "chemical" or style == "spray":
		return "chemical"
	if damage_type == "bullet":
		return "bullet_hell"
	return ""


func ammo_type_for_event(event: Dictionary, valid_ammo_types: Array) -> String:
	var ammo_kind := _normalized_ammo_type(String(event.get("ammo_kind", "")), valid_ammo_types)
	if _ammo_type_list_has(valid_ammo_types, ammo_kind):
		return ammo_kind
	var damage_type := String(event.get("projectile_damage_type", event.get("damage_type", "")))
	return damage_type if _ammo_type_list_has(valid_ammo_types, damage_type) else ""


func _normalized_ammo_type(ammo_type: String, valid_ammo_types: Array) -> String:
	var normalized := ammo_type.to_lower()
	if normalized in ["explosion", "missile"]:
		return "explosive"
	if normalized in ["chemical_splash", "acid"]:
		return "chemical"
	if normalized in ["silk", "thread"]:
		return "web"
	return normalized if _ammo_type_list_has(valid_ammo_types, normalized) else ""


func _ammo_type_list_has(valid_ammo_types: Array, ammo_type: String) -> bool:
	for raw_type in valid_ammo_types:
		if String(raw_type) == ammo_type:
			return true
	return false


func event_vector_value(event: Dictionary, key: String) -> Vector2:
	if event.has(key) and event[key] is Vector2:
		var value: Vector2 = event[key]
		return value
	return Vector2.ZERO


func event_momentum_vector_patch(vector: Vector2, magnitude: float = -1.0) -> Dictionary:
	var resolved_magnitude := magnitude if magnitude >= 0.0 else vector.length()
	var patch := {
		"momentum_vector": vector,
		"momentum_magnitude": resolved_magnitude,
	}
	if resolved_magnitude > 0.001 and vector.length() > 0.001:
		patch["direction"] = vector.normalized()
	return patch


func event_direction_vector(event: Dictionary, target_delta: Vector2, attacker_forward: Vector2, fallback: Vector2 = Vector2.RIGHT) -> Vector2:
	var momentum_vector := event_vector_value(event, "momentum_vector")
	if momentum_vector.length() > 0.001:
		return momentum_vector.normalized()
	var event_direction := event_vector_value(event, "direction")
	if event_direction.length() > 0.001:
		return event_direction.normalized()
	if target_delta.length() > 0.001:
		return target_delta.normalized()
	if attacker_forward.length() > 0.001:
		return attacker_forward.normalized()
	if fallback.length() > 0.001:
		return fallback.normalized()
	return Vector2.RIGHT


func event_momentum_magnitude(event: Dictionary, fallback: float = 0.0) -> float:
	var momentum_vector := event_vector_value(event, "momentum_vector")
	if momentum_vector.length() > 0.001:
		return momentum_vector.length()
	if event.has("momentum_magnitude"):
		return maxf(0.0, float(event.get("momentum_magnitude", fallback)))
	if event.has("momentum"):
		return maxf(0.0, float(event.get("momentum", fallback)))
	return maxf(0.0, fallback)


func gun_drive_projectile_momentum_mult(_gun_drive_ratio: float) -> float:
	return 1.0


func projectile_drive_momentum_mult_for_event(event: Dictionary) -> float:
	if not event.has("gun_drive_ratio"):
		return 1.0
	return gun_drive_projectile_momentum_mult(float(event.get("gun_drive_ratio", 1.0)))


func projectile_drive_momentum_fields(event: Dictionary) -> Dictionary:
	if not bool(event.get("projectile", false)):
		return {}
	var base_momentum := maxf(0.0, float(event.get("projectile_base_momentum", event.get("projectile_momentum", 0.0))))
	var drive_mult := projectile_drive_momentum_mult_for_event(event)
	return {
		"projectile_base_momentum": base_momentum,
		"projectile_drive_momentum_mult": drive_mult,
		"projectile_effective_momentum": base_momentum * drive_mult,
	}


func projectile_default_momentum_for_event(event: Dictionary, constants: Dictionary) -> float:
	match projectile_behavior_key(event):
		"true_bullet":
			return float(constants.get("projectile_momentum_true_bullet", 96.0))
		"explosive":
			return float(constants.get("projectile_momentum_explosive", 92.0))
		"bullet_hell":
			return float(constants.get("projectile_momentum_bullet_hell", 48.0))
		"laser":
			return float(constants.get("projectile_momentum_laser", 18.0))
		"chemical":
			return float(constants.get("projectile_momentum_chemical", 16.0))
	return 0.0


func projectile_collision_speed_for_event(event: Dictionary, constants: Dictionary) -> float:
	if not bool(event.get("projectile", false)):
		return 0.0
	if float(event.get("projectile_collision_speed", 0.0)) > 0.0:
		return maxf(0.0, float(event["projectile_collision_speed"]))
	var speed_unit := float(constants.get("projectile_speed_unit", 6.0))
	match projectile_behavior_key(event):
		"true_bullet":
			return float(constants.get("projectile_speed_true_bullet", 32.0))
		"laser":
			return float(constants.get("projectile_speed_laser", 60.0))
		"explosive":
			return clampf(float(event.get("projectile_speed_mult", 1.6)), 0.9, 2.4) * speed_unit
		"bullet_hell":
			return clampf(float(event.get("projectile_speed_mult", constants.get("bullet_hell_default_speed_mult", 2.8))), 1.5, 5.0) * speed_unit
		"chemical":
			return clampf(float(event.get("projectile_speed_mult", constants.get("chemical_projectile_default_speed_mult", 0.72))), 0.35, 1.45) * speed_unit
	return speed_unit


func projectile_mass_for_event(event: Dictionary, constants: Dictionary, collision_speed: float = -1.0) -> float:
	if not bool(event.get("projectile", false)):
		return 0.0
	if float(event.get("projectile_mass", 0.0)) > 0.0:
		return maxf(0.0, float(event["projectile_mass"]))
	var speed := collision_speed if collision_speed > 0.0 else projectile_collision_speed_for_event(event, constants)
	if event.has("projectile_momentum") and float(event.get("projectile_momentum", 0.0)) > 0.0 and speed > 0.001:
		return maxf(0.01, float(event["projectile_momentum"]) * projectile_drive_momentum_mult_for_event(event) / speed)
	match projectile_behavior_key(event):
		"true_bullet":
			return float(constants.get("projectile_mass_true_bullet", 3.0))
		"explosive":
			return float(constants.get("projectile_mass_explosive", 9.6))
		"bullet_hell":
			return float(constants.get("projectile_mass_bullet_hell", 2.85))
		"laser":
			return float(constants.get("projectile_mass_laser", 0.3))
		"chemical":
			return float(constants.get("projectile_mass_chemical", 3.7))
	return 1.0


func projectile_momentum_state_for_event(event: Dictionary, constants: Dictionary) -> Dictionary:
	if not bool(event.get("projectile", false)):
		return {"momentum": 0.0, "fields": {}}
	if float(event.get("projectile_momentum", 0.0)) > 0.0:
		var base_momentum := maxf(0.0, float(event.get("projectile_momentum", 0.0)))
		var drive_mult := projectile_drive_momentum_mult_for_event(event)
		var effective := base_momentum * drive_mult
		return {
			"momentum": effective,
			"fields": {
				"projectile_base_momentum": base_momentum,
				"projectile_drive_momentum_mult": drive_mult,
				"projectile_effective_momentum": effective,
			},
		}
	var speed := projectile_collision_speed_for_event(event, constants)
	var mass := projectile_mass_for_event(event, constants, speed)
	return {"momentum": maxf(0.0, mass * speed), "fields": {}}


func projectile_collision_momentum_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("projectile", false)):
		return {"action": "none", "reason": "not_projectile", "momentum": 0.0, "event_patch": {}}
	var projectile_velocity: Vector2 = context.get("projectile_velocity", Vector2.ZERO) if context.get("projectile_velocity", Vector2.ZERO) is Vector2 else Vector2.ZERO
	var target_velocity: Vector2 = context.get("target_velocity", Vector2.ZERO) if context.get("target_velocity", Vector2.ZERO) is Vector2 else Vector2.ZERO
	var projectile_speed := projectile_velocity.length()
	var fallback_direction: Vector2 = context.get("fallback_direction", Vector2.RIGHT) if context.get("fallback_direction", Vector2.RIGHT) is Vector2 else Vector2.RIGHT
	var projectile_direction := projectile_velocity.normalized() if projectile_speed > 0.001 else (fallback_direction.normalized() if fallback_direction.length() > 0.001 else Vector2.RIGHT)
	var relative_velocity := projectile_velocity - target_velocity
	var closing_speed := maxf(0.0, relative_velocity.dot(projectile_direction))
	var projectile_mass := float(context.get("projectile_mass", 0.0))
	var momentum_scale := maxf(0.0, float(context.get("momentum_scale", 1.0)))
	var explicit_momentum := float(context.get("explicit_momentum", 0.0))
	var momentum := projectile_mass * closing_speed * momentum_scale
	if explicit_momentum > 0.0 and String(context.get("behavior_key", "")) == "true_bullet":
		momentum = explicit_momentum * momentum_scale
	var momentum_vector := projectile_direction * momentum
	var patch := {
		"projectile_mass": projectile_mass,
		"projectile_collision_speed": projectile_speed,
		"projectile_velocity_vector": projectile_velocity,
		"projectile_target_velocity_vector": target_velocity,
		"projectile_relative_velocity_vector": relative_velocity,
		"projectile_closing_speed": closing_speed,
		"projectile_momentum_resolved": momentum,
		"momentum": momentum,
		"momentum_vector": momentum_vector,
		"momentum_magnitude": momentum,
	}
	if momentum > 0.001 and momentum_vector.length() > 0.001:
		patch["direction"] = projectile_direction
	return {
		"action": "resolve_projectile_collision_momentum",
		"momentum": momentum,
		"projectile_direction": projectile_direction,
		"closing_speed": closing_speed,
		"relative_velocity": relative_velocity,
		"event_patch": patch,
	}


func projectile_stagger_impact_position_intent(event: Dictionary, target_position: Vector2) -> Dictionary:
	var position := target_position
	var source := "target_position"
	if event.has("hit_position_combat") and event["hit_position_combat"] is Vector2:
		position = event["hit_position_combat"]
		source = "hit_position_combat"
	elif event.has("projectile_impact_position") and event["projectile_impact_position"] is Vector2:
		position = event["projectile_impact_position"]
		source = "projectile_impact_position"
	return {
		"action": "resolve_projectile_stagger_impact_position",
		"position": position,
		"source": source,
	}


func projectile_consumes_on_first_hit(event: Dictionary, constants: Dictionary) -> bool:
	if not bool(event.get("projectile", false)):
		return false
	if bool(event.get("non_damage", false)):
		return false
	var style := String(event.get("projectile_style", ""))
	if style in ["web", "web_snap", "blind", "shield", "chain"]:
		return false
	var damage_type := String(event.get("damage_type", ""))
	var damage_types: Array = constants.get("projectile_damage_types", []) if constants.get("projectile_damage_types", []) is Array else []
	return damage_type in damage_types or style in ["beam", "chaos", "true_bullet", "bullet_hell", "spray", "missile", "explosive", "blast"]


func gun_projectile_damage_mult_max_for_data(data: Dictionary, resolved_gun_kind: String, resolved_ammo_kind: String, constants: Dictionary) -> float:
	if bool(data.get("non_damage", false)):
		return 0.0
	if data.has("gun_projectile_damage_mult"):
		return maxf(0.0, float(data.get("gun_projectile_damage_mult", 0.0)))
	var gun_kind := resolved_gun_kind.to_lower()
	var ammo_kind := resolved_ammo_kind.to_lower()
	match gun_kind:
		"sniper":
			return float(constants.get("standard_sniper_gun_damage_coeff", 20.0))
		"rifle":
			return 4.0
		"laser_gun":
			return 3.0
		"sprayer":
			return 2.0
		"grenade_launcher":
			return 4.0
		"missile_launcher":
			return 5.0
		"web_gun":
			return 0.0
	match ammo_kind:
		"laser":
			return 3.0
		"chemical":
			return 2.0
		"explosive":
			return 4.0
		"web":
			return 0.0
	return 1.0


func gun_projectile_damage_mult_for_event(event: Dictionary, resolved_gun_kind: String, resolved_ammo_kind: String, constants: Dictionary, current_multiplier_fn: Callable = Callable()) -> float:
	if bool(event.get("non_damage", false)):
		return 0.0
	if event.has("gun_projectile_damage_mult_current") and not event.has("gun_drive_allocated") and not event.has("gun_drive_max"):
		return maxf(0.0, float(event.get("gun_projectile_damage_mult_current", 0.0)))
	var max_mult := gun_projectile_damage_mult_max_for_data(event, resolved_gun_kind, resolved_ammo_kind, constants)
	var max_drive := maxf(0.0, float(event.get("gun_drive_max", event.get("momentum_max", 0.0))))
	var allocated := clampf(float(event.get("gun_drive_allocated", max_drive)), 0.0, max_drive)
	if current_multiplier_fn.is_valid():
		return float(current_multiplier_fn.call(max_mult, allocated, max_drive, false))
	if max_drive <= 0.001:
		return max_mult
	return max_mult * (allocated / max_drive)


func projectile_damage_coeffs_for_event(event: Dictionary, resolved_gun_kind: String, resolved_ammo_kind: String, constants: Dictionary, current_multiplier_fn: Callable = Callable()) -> Dictionary:
	var gun_mult := gun_projectile_damage_mult_for_event(event, resolved_gun_kind, resolved_ammo_kind, constants, current_multiplier_fn)
	return {
		"ammo": 1.0,
		"gun": gun_mult,
		"fields": {
			"gun_projectile_damage_mult_current": gun_mult,
			"gun_projectile_damage_mult": gun_projectile_damage_mult_max_for_data(event, resolved_gun_kind, resolved_ammo_kind, constants),
		},
	}


func projectile_raw_damage_for_momentum(event: Dictionary, projectile_momentum: float, resolved_gun_kind: String, resolved_ammo_kind: String, constants: Dictionary, current_multiplier_fn: Callable = Callable()) -> float:
	if projectile_momentum <= 0.0:
		return 0.0
	var coeffs := projectile_damage_coeffs_for_event(event, resolved_gun_kind, resolved_ammo_kind, constants, current_multiplier_fn)
	return projectile_momentum * float(coeffs.get("gun", 1.0))


func default_recoil_transfer_for_projectile(event: Dictionary) -> float:
	match projectile_behavior_key(event):
		"true_bullet":
			return 0.85
		"explosive":
			return 1.0
		"bullet_hell":
			return 0.7
		"laser":
			return 0.35
		"chemical":
			return 0.55
	return 0.65


func weapon_recoil_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("projectile", false)):
		return {"action": "none", "reason": "not_projectile"}
	if bool(context.get("weapon_recoil_applied", false)):
		return {"action": "none", "reason": "already_applied"}
	var projectile_velocity: Vector2 = context.get("projectile_velocity", Vector2.ZERO) if context.get("projectile_velocity", Vector2.ZERO) is Vector2 else Vector2.ZERO
	if projectile_velocity.length() <= 0.001:
		return {"action": "none", "reason": "no_velocity"}
	var launch_momentum := float(context.get("launch_momentum", 0.0))
	if launch_momentum <= 0.001:
		return {"action": "none", "reason": "no_momentum"}
	var shooter_mass := maxf(1.0, float(context.get("shooter_mass", 1.0)))
	var recoil_amount := launch_momentum / shooter_mass
	if recoil_amount <= 0.0001:
		return {"action": "none", "reason": "small_recoil"}
	var direction := projectile_velocity.normalized()
	return {
		"action": "apply_weapon_recoil",
		"direction": direction,
		"launch_momentum": launch_momentum,
		"recoil_amount": recoil_amount,
		"event_patch": {
			"weapon_recoil_momentum": launch_momentum,
			"weapon_recoil_amount": recoil_amount,
			"weapon_recoil_direction": -direction,
			"weapon_recoil_applied": true,
		},
	}


func heat_tags_for_projectile_event(event: Dictionary) -> Array:
	var tags: Array = ["projectile"]
	var tag_source := ""
	for key in ["gun_kind", "ammo_kind", "projectile_style", "projectile_behavior", "module_action_profile"]:
		var value := String(event.get(key, ""))
		if value != "":
			tag_source += " " + value.to_lower()
	if tag_source.contains("laser"):
		tags.append("laser")
	if tag_source.contains("chemical"):
		tags.append("chemical")
	if tag_source.contains("missile") or tag_source.contains("explosive") or tag_source.contains("grenade"):
		tags.append("missile")
	return tags


func heat_reason_for_tags(tags: Array, source: String = "") -> String:
	var reason_tags: Array = []
	for raw_tag in tags:
		var tag := String(raw_tag).strip_edges().to_lower()
		if tag.begins_with("heat_event:"):
			tag = tag.substr("heat_event:".length())
		elif tag.begins_with("heat:"):
			tag = tag.substr("heat:".length())
		if tag == "":
			continue
		var heat_tag := "heat:%s" % tag
		if not reason_tags.has(heat_tag):
			reason_tags.append(heat_tag)
	if source.strip_edges() != "":
		reason_tags.append(source)
	return " ".join(reason_tags)


func heat_reason_for_projectile_event(event: Dictionary) -> String:
	return heat_reason_for_tags(heat_tags_for_projectile_event(event), "projectile")


func is_chemical_projectile_event(event: Dictionary) -> bool:
	if bool(event.get("non_damage", false)):
		return false
	if not bool(event.get("projectile", false)):
		return false
	var damage_type := String(event.get("damage_type", event.get("projectile_damage_type", "")))
	return damage_type == "chemical"


func chemical_firework_event(event: Dictionary) -> bool:
	var behavior := String(event.get("projectile_behavior", ""))
	if behavior == "chemical_firework":
		return true
	var path := String(event.get("travel_path", "straight"))
	return path in ["firework", "shotgun", "burst", "sine", "arc_u"]


func prepared_chemical_projectile_event(event: Dictionary, constants: Dictionary) -> Dictionary:
	var prepared := event.duplicate(true)
	prepared["damage_type"] = "chemical"
	prepared["projectile_damage_type"] = "chemical"
	if String(prepared.get("projectile_style", "")) == "":
		prepared["projectile_style"] = "spray"
	if String(prepared.get("projectile_behavior", "")) == "":
		prepared["projectile_behavior"] = "chemical_firework" if chemical_firework_event(prepared) else "chemical_line"
	var default_speed := float(constants.get("chemical_projectile_default_speed_mult", 0.72))
	if not prepared.has("projectile_speed_mult") or float(prepared.get("projectile_speed_mult", 0.0)) <= 0.0:
		prepared["projectile_speed_mult"] = default_speed
	prepared["projectile_speed_mult"] = clampf(float(prepared.get("projectile_speed_mult", default_speed)), 0.35, 1.45)
	if not prepared.has("chemical_dot_duration"):
		prepared["chemical_dot_duration"] = float(constants.get("chemical_dot_default_duration", 3.2))
	if not prepared.has("chemical_dot_mult"):
		prepared["chemical_dot_mult"] = float(constants.get("chemical_dot_default_mult", 0.42))
	if not prepared.has("chemical_frontload"):
		prepared["chemical_frontload"] = float(constants.get("chemical_dot_default_frontload", 0.22))
	if not prepared.has("chemical_pellets"):
		prepared["chemical_pellets"] = 7 if chemical_firework_event(prepared) else 1
	if not prepared.has("chemical_spread"):
		prepared["chemical_spread"] = 0.54 if chemical_firework_event(prepared) else 0.0
	return prepared


func chemical_projectile_travel_time(event: Dictionary, constants: Dictionary) -> float:
	var travel_range := maxf(0.4, float(event.get("range", event.get("projectile_range", 1.2))))
	var speed_mult := clampf(float(event.get("projectile_speed_mult", constants.get("chemical_projectile_default_speed_mult", 0.72))), 0.35, 1.45)
	return clampf(travel_range / (2.15 * speed_mult), float(constants.get("chemical_projectile_min_travel", 0.32)), float(constants.get("chemical_projectile_max_travel", 1.25)))


func chemical_queue_intent(event: Dictionary, direction: Vector2, fallback_direction: Vector2, constants: Dictionary) -> Dictionary:
	var shot_event := prepared_chemical_projectile_event(event, constants)
	var shot_direction := direction
	if shot_direction.length() <= 0.01:
		shot_direction = fallback_direction
	if shot_direction.length() <= 0.01:
		shot_direction = Vector2.RIGHT
	shot_event["direction"] = shot_direction.normalized()
	shot_event["chemical_projectile_ready"] = true
	var travel_time := chemical_projectile_travel_time(shot_event, constants)
	return {
		"event": shot_event,
		"timer": travel_time,
		"signal_time": travel_time + 0.12,
	}


func is_missile_projectile_event(event: Dictionary) -> bool:
	if bool(event.get("missile_flight_ready", false)):
		return false
	if bool(event.get("non_damage", false)):
		return false
	if not bool(event.get("projectile", false)):
		return false
	return String(event.get("projectile_style", "")) == "missile" and String(event.get("travel_path", "")) == "homing"


func missile_projectile_travel_time(range_hint: float, event: Dictionary, constants: Dictionary) -> float:
	var safe_range := maxf(0.4, range_hint)
	var speed_mult := clampf(float(event.get("projectile_speed_mult", constants.get("standard_missile_speed_mult", 1.05))), 0.45, 1.45)
	return clampf(safe_range / (2.05 * speed_mult), 0.38, 2.2)


func missile_queue_intent(event: Dictionary, direction: Vector2, target_distance: float, constants: Dictionary) -> Dictionary:
	var shot_event := event.duplicate(true)
	shot_event["projectile_style"] = "missile"
	shot_event["projectile_behavior"] = "explosive"
	shot_event["travel_path"] = "homing"
	shot_event["aim_locked"] = true
	shot_event["direction"] = direction
	shot_event["range"] = maxf(float(shot_event.get("range", constants.get("standard_missile_range_m", 3.4))), target_distance)
	var travel_time := missile_projectile_travel_time(target_distance, shot_event, constants)
	return {
		"event": shot_event,
		"timer": travel_time,
		"signal_time": travel_time + 0.12,
		"last_direction": direction,
	}


func web_trace_event(base_event: Dictionary, impact_position: Vector2) -> Dictionary:
	var event := base_event.duplicate(true)
	event["projectile_impact_position"] = impact_position
	event["projectile_style"] = "web"
	event["projectile_behavior"] = "web_tether"
	event["travel_path"] = "tether"
	event["damage_type"] = "blunt"
	event["non_damage"] = true
	event["projectile_trace_spawned"] = true
	return event


func trace_payload(event: Dictionary, projected_segment: Dictionary, fallback_position: Vector2, constants: Dictionary) -> Dictionary:
	return {
		"start": projected_segment.get("start", fallback_position),
		"end": projected_segment.get("end", fallback_position),
		"damage_type": String(event.get("damage_type", "bullet")),
		"projectile_style": String(event.get("projectile_style", projectile_style_for_damage(String(event.get("damage_type", "bullet"))))),
		"travel_path": String(event.get("travel_path", "straight")),
		"projectile_speed_mult": float(event.get("projectile_speed_mult", constants.get("bullet_hell_default_speed_mult", 2.8))),
	}
