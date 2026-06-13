extends RefCounted
class_name RuntimeContactService


func collider_uses_torso_damage(collider: Dictionary) -> bool:
	return String(collider.get("damage_proxy", "")).to_lower() == "torso" or (collider.has("independent_damage") and not bool(collider.get("independent_damage", true)))


func socket_key(collider: Dictionary) -> String:
	if collider_uses_torso_damage(collider):
		return "torso:%d:proxy" % int(collider.get("damage_proxy_torso_unit_index", collider.get("torso_unit_index", 0)))
	return "%s:%s:%d" % [String(collider.get("part_kind", "")), str(collider.get("node_index", collider.get("part_index", ""))), int(collider.get("torso_unit_index", -1))]


func pair_key(unit_a_id: int, collider_a: Dictionary, unit_b_id: int, collider_b: Dictionary) -> String:
	var aid := unit_a_id
	var bid := unit_b_id
	var a_socket := socket_key(collider_a)
	var b_socket := socket_key(collider_b)
	if aid > bid:
		var tmp_id := aid
		aid = bid
		bid = tmp_id
		var tmp_socket := a_socket
		a_socket = b_socket
		b_socket = tmp_socket
	return "%d|%s--%d|%s" % [aid, a_socket, bid, b_socket]


func directed_contact_key(attacker_id: int, attacker_collider: Dictionary, target_id: int, target_collider: Dictionary) -> String:
	return "%d|%s->%d|%s" % [attacker_id, socket_key(attacker_collider), target_id, socket_key(target_collider)]


func collider_priority(raw_collider) -> int:
	if not (raw_collider is Dictionary):
		return 999
	var collider: Dictionary = raw_collider
	var part_kind := String(collider.get("part_kind", ""))
	var independent := bool(collider.get("independent_damage", false)) and part_kind != "torso"
	if independent:
		if part_kind == "terminal":
			return 0
		return 1
	if part_kind == "torso":
		return 8
	if collider_uses_torso_damage(collider):
		return 9
	return 5


func sorted_colliders(colliders: Array) -> Array:
	var sorted := colliders.duplicate()
	sorted.sort_custom(Callable(self, "_collider_sort"))
	return sorted


func _collider_sort(a, b) -> bool:
	return collider_priority(a) < collider_priority(b)


func damage_coeff(collider: Dictionary, constants: Dictionary) -> float:
	if collider_uses_torso_damage(collider):
		return float(constants.get("part_damage_coeff_torso", 1.0))
	if collider.has("damage_coeff"):
		return maxf(0.0, float(collider.get("damage_coeff", 0.0)))
	match String(collider.get("part_kind", "")):
		"torso":
			return float(constants.get("part_damage_coeff_torso", 1.0))
		"terminal":
			return float(constants.get("part_damage_coeff_terminal_ranged", 0.8)) if String(collider.get("terminal_weapon_kind", "")).to_lower() == "ranged" else float(constants.get("part_damage_coeff_terminal_melee", 3.2))
		"barrier_tile":
			return float(constants.get("part_damage_coeff_barrier", 1.0))
		_:
			return float(constants.get("part_damage_coeff_limb", 1.8))


func break_coeff(collider: Dictionary, constants: Dictionary) -> float:
	if collider_uses_torso_damage(collider):
		return float(constants.get("part_break_coeff_torso", 0.5))
	if collider.has("break_coeff"):
		return maxf(0.0, float(collider.get("break_coeff", 0.0)))
	match String(collider.get("part_kind", "")):
		"torso":
			return float(constants.get("part_break_coeff_torso", 0.5))
		"terminal":
			return float(constants.get("part_break_coeff_terminal_ranged", 0.5)) if String(collider.get("terminal_weapon_kind", "")).to_lower() == "ranged" else float(constants.get("part_break_coeff_terminal_melee", 1.0))
		"barrier_tile":
			return float(constants.get("part_break_coeff_barrier", 0.5))
		_:
			return float(constants.get("part_break_coeff_limb", 0.5))


func part_stiffness(collider: Dictionary, size_mult: float, constants: Dictionary) -> float:
	var base := float(constants.get("part_stiffness_base_momentum", 768.0))
	var mult := maxf(0.001, size_mult)
	if collider_uses_torso_damage(collider):
		return base * 2.0 * mult
	if collider.has("stiffness_momentum"):
		return maxf(1.0, float(collider.get("stiffness_momentum", 0.0)))
	match String(collider.get("part_kind", "")):
		"torso":
			return base * 2.0 * mult
		"terminal":
			var terminal_kind := String(collider.get("terminal_weapon_kind", "")).to_lower()
			return base * (0.8 if terminal_kind == "ranged" else 2.0) * mult
		"barrier_tile":
			return base * mult
		_:
			return base * mult


func path_stiffness(collider: Dictionary, size_mult: float, constants: Dictionary) -> float:
	var base := float(constants.get("part_stiffness_base_momentum", 768.0))
	var mult := maxf(0.001, size_mult)
	if collider_uses_torso_damage(collider):
		return base * 2.0 * mult
	if collider.has("path_stiffness_momentum"):
		return maxf(1.0, float(collider.get("path_stiffness_momentum", 0.0)))
	var torso_stiffness := base * 2.0 * mult
	var limb_stiffness := base * mult
	var self_stiffness := part_stiffness(collider, mult, constants)
	match String(collider.get("part_kind", "")):
		"torso":
			return self_stiffness
		"terminal":
			return maxf(1.0, minf(self_stiffness, minf(limb_stiffness, torso_stiffness)))
		"barrier_tile":
			return self_stiffness
		_:
			return maxf(1.0, minf(self_stiffness, torso_stiffness))


func break_threshold(collider: Dictionary, size_mult: float, constants: Dictionary) -> float:
	return maxf(0.5, path_stiffness(collider, size_mult, constants) * break_coeff(collider, constants) * float(constants.get("break_stiffness_scale", 0.0045)))


func passive_contact_scrape_factor(collider: Dictionary, constants: Dictionary) -> float:
	var base := float(constants.get("passive_contact_scrape_mult", 0.42))
	match String(collider.get("part_kind", "")):
		"terminal":
			return base
		"limb_muscle":
			return base * maxf(0.25, float(collider.get("contact_damage_mult", 0.18)))
		"joint":
			return base * 0.18
	return base * 0.28


func meta_safe_part_index(part_index: int) -> String:
	return "m%d" % abs(part_index) if part_index < 0 else str(part_index)


func passive_contact_damage_key(attacker_id: int, attacker_collider: Dictionary, target_id: int, target_collider: Dictionary, state_key: String) -> String:
	return "passive_contact_%d_%d_%s_%s_%s_%s_%s" % [
		attacker_id,
		target_id,
		meta_safe_part_index(int(attacker_collider.get("part_index", -1))),
		String(attacker_collider.get("part_kind", "")),
		meta_safe_part_index(int(target_collider.get("part_index", -1))),
		String(target_collider.get("part_kind", "")),
		state_key,
	]


func unit_contact_radius(stats: Dictionary, constants: Dictionary) -> float:
	var body_radius := maxf(0.04, float(stats.get("radius", 0.22)))
	var body_length := maxf(0.12, float(stats.get("length", 0.7)))
	var limb_count := maxi(1, int(stats.get("group_count", int(constants.get("attack_group_count", 6)))))
	var limb_bonus := clampf(float(limb_count) * 0.012, 0.02, 0.11)
	return clampf((body_radius * 1.18 + sqrt(body_radius * body_length) * 0.18 + limb_bonus) * float(constants.get("unit_body_spacing_mult", 1.0)), 0.18, 4.6)


func unit_effective_mass(stats: Dictionary) -> float:
	return maxf(1.0, float(stats.get("mass", 1.0)))


func unit_thruster_power(stats: Dictionary) -> float:
	return maxf(0.0, float(stats.get("boost_momentum", 0.0))) / unit_effective_mass(stats)


func unit_knockback_resist(stats: Dictionary) -> float:
	return clampf(float(stats.get("knockback_resist", 0.0)), 0.0, 0.68)


func unit_impulse_motion_mult(stats: Dictionary) -> float:
	return clampf(1.0 - unit_knockback_resist(stats) * 0.72, 0.48, 1.12)


func unit_melee_stability_threshold(stats: Dictionary, constants: Dictionary) -> float:
	var floor := float(constants.get("melee_stability_threshold_floor", 28.0))
	return maxf(floor, float(stats.get("melee_stability_threshold", floor)))


func unit_posture_anchor(stats: Dictionary, opposing_mass: float) -> float:
	var mass := unit_effective_mass(stats)
	var thruster := unit_thruster_power(stats)
	var stabilization := clampf(float(stats.get("recoil_stabilization", stats.get("attitude_control", 0.85))), 0.0, 2.6)
	var thruster_anchor := thruster / maxf(0.001, thruster + opposing_mass * 0.36 + mass * 0.04 + 6.0)
	var control_anchor := clampf(unit_knockback_resist(stats) + maxf(0.0, stabilization - 0.7) * 0.08, 0.0, 0.5)
	return clampf(thruster_anchor * 0.78 + control_anchor, 0.0, 0.82)


func damage_type(collider: Dictionary, melee_damage_types: Array) -> String:
	if collider_uses_torso_damage(collider):
		return "blunt"
	var result := String(collider.get("damage_type", "blunt"))
	if not melee_damage_types.has(result):
		return "blunt"
	return result


func material_class(collider: Dictionary) -> String:
	if collider_uses_torso_damage(collider):
		return "body"
	var result := String(collider.get("material_class", "body"))
	if result == "gun" or result == "missile_launcher" or result == "web_gun":
		return "body"
	return result


func contact_source(collider: Dictionary) -> String:
	if bool(collider.get("independent_damage", false)) and String(collider.get("part_kind", "")) != "torso":
		return "active_module_contact"
	return "default_body_contact"


func runtime_pair_intent(context: Dictionary) -> Dictionary:
	var normal: Vector2 = context.get("normal", Vector2.ZERO)
	if normal.length() <= 0.001:
		return {"should_process": false, "mark_seen": false, "reason": "invalid_normal"}
	normal = normal.normalized()
	if bool(context.get("pair_active", false)):
		return {"should_process": false, "mark_seen": true, "normal": normal, "reason": "active_pair"}
	var constants: Dictionary = Dictionary(context.get("constants", {}))
	var velocity_a: Vector2 = context.get("velocity_a", Vector2.ZERO)
	var velocity_b: Vector2 = context.get("velocity_b", Vector2.ZERO)
	var closing_speed := maxf(0.0, (velocity_a - velocity_b).dot(normal))
	if closing_speed < float(constants.get("passive_contact_min_speed", 0.24)):
		return {"should_process": false, "mark_seen": true, "normal": normal, "closing_speed": closing_speed, "reason": "low_speed"}
	var contact_momentum := closing_speed * (maxf(1.0, float(context.get("mass_a", 1.0))) + maxf(1.0, float(context.get("mass_b", 1.0))))
	if contact_momentum <= 0.001:
		return {"should_process": false, "mark_seen": true, "normal": normal, "closing_speed": closing_speed, "contact_momentum": contact_momentum, "reason": "low_momentum"}
	var source_a := String(context.get("source_a", "default_body_contact"))
	var source_b := String(context.get("source_b", "default_body_contact"))
	var allow_a_damage := true
	var allow_b_damage := true
	if source_a == "active_module_contact" and source_b != "active_module_contact":
		allow_b_damage = false
	elif source_b == "active_module_contact" and source_a != "active_module_contact":
		allow_a_damage = false
	return {
		"should_process": true,
		"mark_seen": true,
		"mark_active": true,
		"normal": normal,
		"closing_speed": closing_speed,
		"contact_momentum": contact_momentum,
		"response_momentum": minf(contact_momentum, minf(maxf(1.0, float(context.get("path_stiffness_a", 1.0))), maxf(1.0, float(context.get("path_stiffness_b", 1.0))))),
		"source_a": source_a,
		"source_b": source_b,
		"allow_a_damage": allow_a_damage,
		"allow_b_damage": allow_b_damage,
		"damage_a": allow_a_damage and not bool(context.get("suppressed_a", false)),
		"damage_b": allow_b_damage and not bool(context.get("suppressed_b", false)),
	}


func gpu_contact_intent(context: Dictionary) -> Dictionary:
	var normal: Vector2 = context.get("normal", Vector2.ZERO)
	if normal.length() <= 0.001:
		return {"should_process": false, "mark_seen": false, "reason": "invalid_normal"}
	normal = normal.normalized()
	var constants: Dictionary = Dictionary(context.get("constants", {}))
	var penetration := maxf(0.0, float(context.get("penetration", 0.0)))
	if penetration <= float(constants.get("runtime_contact_required_overlap", 0.003)):
		return {"should_process": false, "mark_seen": false, "normal": normal, "penetration": penetration, "reason": "shallow"}
	var base := {
		"should_process": false,
		"mark_seen": true,
		"normal": normal,
		"penetration": penetration,
		"position_delta_a": context.get("position_delta_a", Vector2.ZERO),
		"position_delta_b": context.get("position_delta_b", Vector2.ZERO),
	}
	if bool(context.get("pair_active", false)):
		base["reason"] = "active_pair"
		return base
	var source_a := String(context.get("source_a", "default_body_contact"))
	var source_b := String(context.get("source_b", "default_body_contact"))
	var allow_a_damage := true
	var allow_b_damage := true
	if source_a == "active_module_contact" and source_b != "active_module_contact":
		allow_b_damage = false
	elif source_b == "active_module_contact" and source_a != "active_module_contact":
		allow_a_damage = false
	var contact_momentum := maxf(0.0, float(context.get("raw_contact_momentum", context.get("usable_contact_momentum", 0.0))))
	var response_momentum := maxf(0.0, float(context.get("usable_contact_momentum", 0.0)))
	var closing_speed := maxf(0.0, float(context.get("relative_normal_velocity", 0.0)))
	var owner_differs := int(context.get("owner_a_id", 0)) != int(context.get("owner_b_id", 0))
	base.merge({
		"should_process": true,
		"mark_active": true,
		"recovery_a": bool(context.get("recovery_a", false)),
		"recovery_b": bool(context.get("recovery_b", false)),
		"contact_momentum": contact_momentum,
		"response_momentum": response_momentum,
		"closing_speed": closing_speed,
		"vfx_strength": maxf(0.0, float(context.get("vfx_strength", 0.0))),
		"vfx_kind": int(context.get("vfx_kind", 0)),
		"source_a": source_a,
		"source_b": source_b,
		"allow_a_damage": owner_differs and closing_speed >= float(constants.get("passive_contact_min_speed", 0.24)) and allow_a_damage,
		"allow_b_damage": owner_differs and closing_speed >= float(constants.get("passive_contact_min_speed", 0.24)) and allow_b_damage,
		"damage_a": owner_differs and closing_speed >= float(constants.get("passive_contact_min_speed", 0.24)) and allow_a_damage and not bool(context.get("suppressed_a", false)),
		"damage_b": owner_differs and closing_speed >= float(constants.get("passive_contact_min_speed", 0.24)) and allow_b_damage and not bool(context.get("suppressed_b", false)),
		"velocity_delta_a": context.get("velocity_delta_a", Vector2.ZERO),
		"velocity_delta_b": context.get("velocity_delta_b", Vector2.ZERO),
		"apply_velocity_delta": response_momentum > 0.001,
	}, true)
	return base


func damage_intent(context: Dictionary) -> Dictionary:
	var contact_momentum := maxf(0.0, float(context.get("contact_momentum", 0.0)))
	if contact_momentum <= 0.001:
		return {"should_apply": false, "reason": "low_momentum"}
	var attacker_collider: Dictionary = Dictionary(context.get("attacker_collider", {}))
	var target_collider: Dictionary = Dictionary(context.get("target_collider", {}))
	var normal: Vector2 = context.get("normal", Vector2.ZERO)
	var attacker_path_stiffness := maxf(1.0, float(context.get("attacker_path_stiffness", 1.0)))
	var usable_momentum := minf(contact_momentum, attacker_path_stiffness)
	var damage_float := usable_momentum * maxf(0.0, float(context.get("damage_coeff", 0.0))) * float(context.get("contact_damage_scale", 0.09))
	damage_float *= maxf(0.0, float(context.get("vulnerability_multiplier", 1.0)))
	if damage_float <= 0.001:
		return {"should_apply": false, "reason": "zero_damage", "damage_float": damage_float}
	var threshold := maxf(0.0, float(context.get("break_threshold", 0.5)))
	var damage_type_value := String(context.get("damage_type", "blunt"))
	var event := {
		"state": "normal",
		"projectile": false,
		"passive_contact": true,
		"runtime_contact": true,
		"contact_source": String(context.get("contact_source", "runtime_contact")),
		"contact_node_key": socket_key(attacker_collider),
		"contact_segment_key": "%s:%s" % [String(attacker_collider.get("part_kind", "")), str(attacker_collider.get("node_index", attacker_collider.get("part_index", "")))],
		"contact_pair_key": directed_contact_key(int(context.get("attacker_id", 0)), attacker_collider, int(context.get("target_id", 0)), target_collider),
		"damage_resolution_part": socket_key(target_collider),
		"damage_type": damage_type_value,
		"material_class": String(context.get("material_class", "body")),
		"direction": normal,
		"momentum": usable_momentum,
		"momentum_vector": normal * usable_momentum,
		"momentum_magnitude": usable_momentum,
		"raw_momentum": contact_momentum,
		"usable_contact_momentum": usable_momentum,
		"attacker_path_stiffness": attacker_path_stiffness,
		"target_path_stiffness": maxf(1.0, float(context.get("target_path_stiffness", 1.0))),
		"break_threshold": threshold,
		"damage_after_break": damage_float,
		"contact_damage": damage_float,
		"target_part_index": int(target_collider.get("part_index", -1)),
		"target_part_kind": String(target_collider.get("part_kind", "core")),
		"target_part_name": String(target_collider.get("name", "CORE")),
		"target_torso_unit_index": int(target_collider.get("torso_unit_index", -1)),
		"attacker_part_index": int(attacker_collider.get("part_index", -1)),
		"attacker_part_kind": String(attacker_collider.get("part_kind", "")),
		"attacker_terminal_weapon_kind": String(attacker_collider.get("terminal_weapon_kind", "")),
		"hit_position_combat": context.get("hit_position", Vector2.ZERO),
	}
	return {
		"should_apply": true,
		"threshold_blocked": damage_float < threshold,
		"usable_momentum": usable_momentum,
		"damage_float": damage_float,
		"break_threshold": threshold,
		"event": event,
	}


func velocity_response_intent(context: Dictionary) -> Dictionary:
	var contact_momentum := maxf(0.0, float(context.get("contact_momentum", 0.0)))
	if contact_momentum <= 0.001:
		return {"should_apply": false, "reason": "low_momentum"}
	var normal: Vector2 = context.get("normal", Vector2.ZERO)
	if normal.length() <= 0.001:
		return {"should_apply": false, "reason": "invalid_normal"}
	var direction := normal.normalized()
	var mass_a := maxf(1.0, float(context.get("mass_a", 1.0)))
	var mass_b := maxf(1.0, float(context.get("mass_b", 1.0)))
	return {
		"should_apply": true,
		"direction": direction,
		"contact_momentum": contact_momentum,
		"velocity_delta_a": Vector2.ZERO if bool(context.get("anchored_a", false)) else -direction * (contact_momentum / mass_a),
		"velocity_delta_b": Vector2.ZERO if bool(context.get("anchored_b", false)) else direction * (contact_momentum / mass_b),
	}


func runtime_node_array_has(raw_nodes: Array, node_index: int) -> bool:
	for raw_node in raw_nodes:
		if int(raw_node) == node_index:
			return true
	return false


func runtime_action_phase(actions: Array, node_index: int) -> float:
	if node_index < 0:
		return 1.0
	for raw_action in actions:
		if not (raw_action is Dictionary):
			continue
		var action: Dictionary = raw_action
		if not runtime_node_array_has(Array(action.get("target_nodes", [])), node_index):
			continue
		var duration := maxf(0.001, float(action.get("duration", 0.62)))
		return clampf(1.0 - float(action.get("timer", 0.0)) / duration, 0.0, 1.0)
	return 1.0


func runtime_recovery_capable(actions: Array, node_index: int) -> bool:
	if node_index < 0:
		return false
	for raw_action in actions:
		if not (raw_action is Dictionary):
			continue
		var action: Dictionary = raw_action
		if not runtime_node_array_has(Array(action.get("target_nodes", [])), node_index):
			continue
		var duration := maxf(0.001, float(action.get("duration", 0.62)))
		var phase := clampf(1.0 - float(action.get("timer", 0.0)) / duration, 0.0, 1.0)
		var startup_ratio := clampf(float(action.get("startup_ratio", 1.0 / 3.0)), 0.05, 0.95)
		if phase < startup_ratio:
			return true
	return false
