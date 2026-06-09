extends RefCounted
class_name GunActivationService


func _dict(value) -> Dictionary:
	return value if value is Dictionary else {}


func gun_aim_input_mode_for_data(data: Dictionary, projectile_profiles: Array = []) -> String:
	var explicit := String(data.get("gun_aim_input_mode", data.get("aim_input_mode", ""))).to_lower().strip_edges()
	match explicit:
		"turn_keys", "turn", "face_keys", "left_right", "qe":
			return "turn_keys"
		"direction_keys", "direction", "movement_keys", "move_keys":
			return "direction_keys"
	if bool(data.get("turn_keys_steer_joint", false)):
		return "turn_keys"
	var profile := String(data.get("module_action_profile", data.get("gun_activation", ""))).to_lower()
	if projectile_profiles.has(profile):
		return "turn_keys"
	if String(data.get("motion", "")).to_lower() == "gun_activate" or String(data.get("gun_activation", "")) != "":
		return "turn_keys"
	return "direction_keys"


func runtime_binding_profile(binding: Dictionary) -> String:
	var module_part := _dict(binding.get("module_part", {}))
	return String(binding.get("module_action_profile", module_part.get("module_action_profile", "")))


func runtime_binding_is_gun_activation(binding: Dictionary, projectile_profiles: Array = []) -> bool:
	return projectile_profiles.has(runtime_binding_profile(binding))


func runtime_binding_gun_aim_input_mode(binding: Dictionary, projectile_profiles: Array = []) -> String:
	if not runtime_binding_is_gun_activation(binding, projectile_profiles):
		return ""
	var module_part := _dict(binding.get("module_part", {}))
	var merged := module_part.duplicate(true)
	for key in binding.keys():
		merged[key] = binding[key]
	return gun_aim_input_mode_for_data(merged, projectile_profiles)


func runtime_binding_gun_mobility_contract(binding: Dictionary, projectile_profiles: Array = [], mobility_contract: Dictionary = {}) -> Dictionary:
	if not runtime_binding_is_gun_activation(binding, projectile_profiles):
		return {}
	return mobility_contract.duplicate(true)


func active_direction_boost_allowed(state: Dictionary, binding_mobility_contract: Dictionary = {}) -> bool:
	if state.is_empty():
		return false
	if state.has("direction_boost_while_firing"):
		return bool(state.get("direction_boost_while_firing", false))
	return bool(binding_mobility_contract.get("direction_boost_while_firing", false))


func activation_state_active(state: Dictionary) -> bool:
	return not state.is_empty()


func gun_activation_spec(gun_kind: String, profile: String = "", constants: Dictionary = {}) -> Dictionary:
	var gun_key := gun_kind.to_lower()
	var profile_key := profile.to_lower()
	match gun_key:
		"sniper":
			if profile_key != "gun_activate":
				return {}
			return {
				"profile": "gun_activate",
				"semantic": "release_lock",
				"projectile_damage_type": "bullet",
				"projectile_style": "true_bullet",
				"projectile_behavior": "true_bullet",
				"travel_path": "instant_line",
				"default_width": float(constants.get("standard_sniper_projectile_width_m", 0.1)),
				"default_fire_interval": 9999.0,
			}
		"sprayer":
			if profile_key != "gun_activate":
				return {}
			return {
				"profile": "gun_activate",
				"semantic": "hold_stream",
				"projectile_damage_type": "chemical",
				"projectile_style": "spray",
				"projectile_behavior": "chemical_line",
				"travel_path": "straight",
				"default_width": float(constants.get("standard_chemical_sprayer_width_m", 0.16)),
				"default_range": float(constants.get("standard_chemical_sprayer_range_m", 1.6)),
				"default_fire_interval": float(constants.get("standard_chemical_sprayer_fire_interval", 0.24)),
			}
		"rifle":
			if profile_key != "rifle_burst_activate":
				return {}
			return {
				"profile": "rifle_burst_activate",
				"semantic": "hold_burst",
				"projectile_damage_type": "bullet",
				"projectile_style": "bullet_hell",
				"projectile_behavior": "bullet_hell",
				"travel_path": "straight",
				"default_width": 0.12,
				"default_fire_interval": 0.18,
			}
		"grenade_launcher":
			if profile_key != "grenade_arc_activate":
				return {}
			return {
				"profile": "grenade_arc_activate",
				"semantic": "hold_grenade_arc",
				"projectile_damage_type": "explosion",
				"projectile_style": "explosive",
				"projectile_behavior": "explosive",
				"travel_path": "arc_u",
				"default_width": 0.18,
				"default_range": 2.65,
				"default_fire_interval": 1.111111,
			}
		"laser_gun":
			if profile_key != "laser_beam_activate":
				return {}
			return {
				"profile": "laser_beam_activate",
				"semantic": "hold_beam",
				"projectile_damage_type": "laser",
				"projectile_style": "beam",
				"projectile_behavior": "laser",
				"travel_path": "instant_line",
				"default_width": float(constants.get("standard_laser_width_m", 0.18)),
				"default_range": float(constants.get("standard_laser_range_m", 4.2)),
				"default_fire_interval": float(constants.get("standard_laser_fire_interval", 0.1)),
			}
		"missile_launcher":
			if profile_key != "missile_lock_activate":
				return {}
			return {
				"profile": "missile_lock_activate",
				"semantic": "release_missile_lock",
				"projectile_damage_type": "bullet",
				"projectile_style": "missile",
				"projectile_behavior": "explosive",
				"travel_path": "homing",
				"default_width": float(constants.get("standard_missile_width_m", 0.2)),
				"default_range": float(constants.get("standard_missile_range_m", 4.2)),
				"default_fire_interval": 9999.0,
			}
		"web_gun":
			if profile_key != "web_tether_activate":
				return {}
			return {
				"profile": "web_tether_activate",
				"semantic": "release_web",
				"projectile_damage_type": "blunt",
				"projectile_style": "web",
				"projectile_behavior": "web_tether",
				"travel_path": "tether",
				"default_width": float(constants.get("standard_web_tether_width_m", 0.12)),
				"default_range": float(constants.get("standard_web_tether_range_m", 4.2)),
				"default_fire_interval": 9999.0,
			}
	return {}


func gun_activation_profile_supports_kind(profile: String, gun_kind: String, ammo_kind: String = "", registry_supported: bool = true, spec: Dictionary = {}) -> bool:
	if not registry_supported:
		return false
	if spec.is_empty():
		return false
	match profile:
		"laser_beam_activate":
			return gun_kind == "laser_gun" and ammo_kind == "laser"
		"rifle_burst_activate":
			return gun_kind == "rifle" and ammo_kind == "bullet"
		"grenade_arc_activate":
			return gun_kind == "grenade_launcher" and ammo_kind == "explosive"
		"web_tether_activate":
			return gun_kind == "web_gun" and ammo_kind == "web"
		"missile_lock_activate":
			return gun_kind == "missile_launcher" and ammo_kind == "explosive"
	return true


func activation_profile_gate(effective_profile: String, spec: Dictionary, profile_supported: bool = true) -> Dictionary:
	var profile_key := effective_profile.to_lower().strip_edges()
	if profile_key == "":
		return {
			"can_start": false,
			"reason": "empty_effective_profile",
			"effective_profile": profile_key,
		}
	if spec.is_empty():
		return {
			"can_start": false,
			"reason": "empty_spec",
			"effective_profile": profile_key,
		}
	if not profile_supported:
		return {
			"can_start": false,
			"reason": "unsupported_profile",
			"effective_profile": profile_key,
		}
	return {
		"can_start": true,
		"reason": "",
		"effective_profile": profile_key,
	}


func gun_drive_aim_speed_mult(gun_drive_ratio: float) -> float:
	if gun_drive_ratio < 1.0:
		return clampf(0.45 + gun_drive_ratio * 0.55, 0.28, 1.0)
	return clampf(1.0 + sqrt(maxf(0.0, gun_drive_ratio - 1.0)) * 0.26, 1.0, 1.45)


func activation_rotate_speed(module_part: Dictionary, default_turn_speed: float, gun_drive_ratio: float = 1.0) -> float:
	var rotate_speed := float(module_part.get("gun_rotate_speed", 0.0))
	if rotate_speed <= 0.0:
		rotate_speed = maxf(0.0, default_turn_speed)
	return rotate_speed * gun_drive_aim_speed_mult(gun_drive_ratio)


func activation_source_gate(segment: Dictionary) -> Dictionary:
	if segment.is_empty():
		return {
			"can_start": false,
			"reason": "missing_source",
			"terminal_weapon_kind": "",
			"projectile": false,
		}
	var terminal_kind := String(segment.get("terminal_weapon_kind", "")).to_lower().strip_edges()
	var projectile := bool(segment.get("projectile", false))
	if terminal_kind != "ranged":
		return {
			"can_start": false,
			"reason": "not_ranged_terminal",
			"terminal_weapon_kind": terminal_kind,
			"projectile": projectile,
		}
	if not projectile:
		return {
			"can_start": false,
			"reason": "not_projectile_terminal",
			"terminal_weapon_kind": terminal_kind,
			"projectile": false,
		}
	return {
		"can_start": true,
		"reason": "",
		"terminal_weapon_kind": terminal_kind,
		"projectile": true,
	}


func activation_direction(segment: Dictionary, fallback_forward: Vector2 = Vector2.RIGHT) -> Vector2:
	var direction := Vector2.ZERO
	if segment.get("a", null) is Vector2 and segment.get("b", null) is Vector2:
		direction = Vector2(segment.get("b", Vector2.ZERO)) - Vector2(segment.get("a", Vector2.ZERO))
	if direction.length() <= 0.01:
		direction = fallback_forward
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	return direction.normalized()


func activation_event_direction(state: Dictionary, binding_direction: Vector2 = Vector2.ZERO, fallback_forward: Vector2 = Vector2.RIGHT) -> Vector2:
	var direction := Vector2.ZERO
	if state.get("aim_direction", Vector2.ZERO) is Vector2:
		direction = state.get("aim_direction", Vector2.ZERO)
	if direction.length() <= 0.01:
		direction = binding_direction
	if direction.length() <= 0.01:
		direction = fallback_forward
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	return direction.normalized()


func activation_event_source_identity(binding: Dictionary, gun_source: Dictionary = {}) -> Dictionary:
	var target_nodes: Array = Array(binding.get("target_nodes", [])).duplicate(true)
	var node_index := int(target_nodes[target_nodes.size() - 1]) if not target_nodes.is_empty() else int(binding.get("attack_key", 1)) - 1
	if gun_source.has("runtime_target_nodes"):
		target_nodes = Array(gun_source.get("runtime_target_nodes", [])).duplicate(true)
	node_index = int(gun_source.get("source_gun_node", gun_source.get("source_node_index", node_index)))
	return {
		"runtime_target_nodes": target_nodes,
		"source_gun_node": node_index,
		"source_node_index": node_index,
	}


func runtime_gun_source_payload(segment: Dictionary, group: Dictionary, node_index: int, target_nodes: Array, fallback_position: Vector2, fallback_forward: Vector2 = Vector2.RIGHT) -> Dictionary:
	if segment.is_empty():
		return {}
	var terminal_kind := String(segment.get("terminal_weapon_kind", group.get("terminal_weapon_kind", ""))).to_lower()
	var material_class := String(group.get("material_class", segment.get("material_class", ""))).to_lower()
	var is_gun := terminal_kind == "ranged" or bool(segment.get("projectile", false)) or bool(group.get("projectile", false)) or material_class in ["gun", "missile_launcher", "web_gun"]
	if not is_gun:
		return {}
	var root := fallback_position
	if segment.get("a", null) is Vector2:
		root = segment.get("a", fallback_position)
	var muzzle := root
	if segment.get("b", null) is Vector2:
		muzzle = segment.get("b", root)
	var source_segment := segment.duplicate(true)
	var source_group := group.duplicate(true)
	return {
		"source_gun_node": int(node_index),
		"source_node_index": int(node_index),
		"runtime_target_nodes": target_nodes.duplicate(true),
		"segment": source_segment,
		"group": source_group,
		"muzzle_combat_position": muzzle,
		"muzzle_direction": activation_direction({"a": root, "b": muzzle}, fallback_forward),
	}


func runtime_gun_group_payload(group: Dictionary, drive_info: Dictionary = {}) -> Dictionary:
	var next_group := group.duplicate(true)
	next_group["gun_drive_allocated"] = float(drive_info.get("allocated", 0.0))
	next_group["gun_drive_min"] = float(drive_info.get("min", 0.0))
	next_group["gun_drive_max"] = float(drive_info.get("max", 0.0))
	next_group["gun_drive_ratio"] = float(drive_info.get("ratio", 0.0))
	next_group["gun_drive_ratio_to_max"] = float(drive_info.get("ratio_to_max", 0.0))
	next_group["projectile"] = true
	next_group["projectile_only"] = true
	var material_class := String(next_group.get("material_class", "")).to_lower()
	if material_class == "" or not (material_class in ["gun", "missile_launcher", "web_gun"]):
		next_group["material_class"] = "gun"
	if String(next_group.get("shape", "")).to_lower() == "":
		next_group["shape"] = "rifle"
	return next_group


func binding_drive_allocation_for_node(binding: Dictionary, node_index: int, fallback: float = 0.0) -> float:
	var by_node = binding.get("joint_drive_allocation_by_node", {})
	if not (by_node is Dictionary) or Dictionary(by_node).is_empty():
		by_node = binding.get("allocated_limb_momentum_by_node", {})
	if by_node is Dictionary:
		var node_key := str(node_index)
		if Dictionary(by_node).has(node_key):
			return maxf(0.0, float(Dictionary(by_node).get(node_key, fallback)))
		if Dictionary(by_node).has(node_index):
			return maxf(0.0, float(Dictionary(by_node).get(node_index, fallback)))
	var target_count := maxi(1, Array(binding.get("target_nodes", [])).size())
	if binding.has("joint_drive_allocation_total"):
		return maxf(0.0, float(binding.get("joint_drive_allocation_total", 0.0)) / float(target_count))
	if binding.has("allocated_limb_momentum"):
		return maxf(0.0, float(binding.get("allocated_limb_momentum", 0.0)) / float(target_count))
	return maxf(0.0, fallback)


func gun_drive_info_for_segment(segment: Dictionary, binding: Dictionary, node_index: int) -> Dictionary:
	var min_momentum := maxf(0.0, float(segment.get("momentum_min", 0.0)))
	var max_momentum := maxf(min_momentum, float(segment.get("momentum_max", min_momentum)))
	var fallback := maxf(0.0, float(segment.get("allocated_limb_momentum", segment.get("joint_output_momentum_base", 0.0))))
	var max_bound := max_momentum if max_momentum > min_momentum else maxf(min_momentum, fallback)
	var allocated := clampf(binding_drive_allocation_for_node(binding, node_index, fallback), min_momentum, max_bound)
	var ratio := allocated / maxf(1.0, min_momentum)
	var ratio_to_max := allocated / maxf(1.0, max_momentum)
	return {
		"allocated": allocated,
		"min": min_momentum,
		"max": max_momentum,
		"ratio": ratio,
		"ratio_to_max": ratio_to_max,
	}


func local_turn_sign(input_vector: Vector2) -> int:
	if input_vector.length() <= 0.18:
		return 0
	if absf(input_vector.x) < 0.18:
		return 0
	return -1 if input_vector.x < 0.0 else 1


func rotated_direction(current_direction: Vector2, input_vector: Vector2, rotate_speed: float, delta: float, fallback_forward: Vector2 = Vector2.RIGHT) -> Vector2:
	var current := current_direction.normalized() if current_direction.length() > 0.01 else fallback_forward.normalized()
	if current.length() <= 0.01:
		current = Vector2.RIGHT
	var turn_sign := local_turn_sign(input_vector)
	if turn_sign == 0:
		return current
	var step := float(turn_sign) * maxf(0.0, rotate_speed) * maxf(0.0, delta)
	return current.rotated(step).normalized()


func should_release_activation(action_name: String, action_just_released: bool, action_pressed: bool) -> bool:
	return action_name == "" or action_just_released or not action_pressed


func tick_state_payload(state: Dictionary, delta: float, fallback_aim_input_mode: String = "turn_keys") -> Dictionary:
	var next_state := state.duplicate(true)
	next_state["hold_time"] = maxf(0.0, float(next_state.get("hold_time", 0.0))) + maxf(0.0, delta)
	var aim_input_mode := String(next_state.get("aim_input_mode", fallback_aim_input_mode)).to_lower()
	if aim_input_mode == "":
		aim_input_mode = "turn_keys"
	next_state["aim_input_mode"] = aim_input_mode
	return next_state


func continuous_fire_timer_intent(state: Dictionary, delta: float, event: Dictionary) -> Dictionary:
	var next_state := state.duplicate(true)
	var fire_timer := float(next_state.get("fire_timer", 0.0)) - maxf(0.0, delta)
	var fire_due := fire_timer <= 0.0
	if fire_due:
		fire_timer = maxf(0.05, float(event.get("fire_interval", 0.24)))
	next_state["fire_timer"] = fire_timer
	return {
		"fire_due": fire_due,
		"state": next_state,
	}


func fire_ammo_gate(ammo_kind: String, capacity: int, current: int) -> Dictionary:
	var normalized_kind := ammo_kind.to_lower().strip_edges()
	var normalized_capacity := maxi(0, int(capacity))
	var normalized_current := maxi(0, int(current))
	var ammo_empty := normalized_kind != "" and normalized_capacity > 0 and normalized_current <= 0
	return {
		"can_fire": not ammo_empty,
		"ammo_empty": ammo_empty,
		"ammo_kind": normalized_kind,
		"capacity": normalized_capacity,
		"current": normalized_current,
	}


func tick_route_intent(state: Dictionary, event: Dictionary) -> String:
	if event.is_empty():
		return "event_empty"
	var semantic := String(state.get("activation_semantic", ""))
	if semantic == "hold_grenade_arc" and String(event.get("module_variant_key", "")) == "explosive_arc_salvo":
		return "salvo_preview"
	if semantic in ["hold_stream", "hold_beam", "hold_burst", "hold_grenade_arc"]:
		return "continuous_fire"
	if semantic == "release_web":
		return "hold_aim_pose"
	if semantic == "release_missile_lock":
		return "missile_lock"
	if semantic == "release_lock":
		return "true_bullet_lock"
	return "clear_state"


func aim_pose_payload(event: Dictionary, fallback_forward: Vector2 = Vector2.RIGHT, fallback_node: int = 0) -> Dictionary:
	var node_index := int(event.get("source_gun_node", event.get("source_node_index", event.get("muscle_node", fallback_node))))
	var direction := fallback_forward
	if event.get("direction", Vector2.ZERO) is Vector2:
		direction = event.get("direction", Vector2.ZERO)
	if direction.length() <= 0.01:
		direction = fallback_forward
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	return {
		"node_index": node_index,
		"direction": direction.normalized(),
	}


func activation_event_options_payload(binding: Dictionary, gun_source: Dictionary, module_profile: String, effective_profile: String, gun_kind: String, ammo_kind: String, fallback_target_nodes: Array = [], fallback_node_index: int = 0, fallback_muzzle_position: Vector2 = Vector2.ZERO, fallback_muzzle_direction: Vector2 = Vector2.RIGHT) -> Dictionary:
	var target_nodes: Array = fallback_target_nodes.duplicate(true)
	if gun_source.has("runtime_target_nodes"):
		target_nodes = Array(gun_source.get("runtime_target_nodes", [])).duplicate(true)
	var node_index := int(gun_source.get("source_gun_node", gun_source.get("source_node_index", fallback_node_index)))
	return {
		"runtime_target_nodes": target_nodes,
		"source_gun_node": node_index,
		"source_node_index": node_index,
		"muzzle_combat_position": gun_source.get("muzzle_combat_position", fallback_muzzle_position),
		"muzzle_direction": gun_source.get("muzzle_direction", fallback_muzzle_direction),
		"attack_key": int(binding.get("attack_key", 1)),
		"module_action_profile": module_profile,
		"effective_gun_activation_profile": effective_profile,
		"gun_activation": true,
		"gun_kind": gun_kind,
		"ammo_kind": ammo_kind,
	}


func release_route_intent(state: Dictionary, event: Dictionary) -> Dictionary:
	if event.is_empty():
		return {"route": "clear_pose", "event_patch": {}}
	var semantic := String(state.get("activation_semantic", ""))
	if semantic == "hold_grenade_arc" and String(event.get("module_variant_key", "")) == "explosive_arc_salvo":
		return {"route": "salvo_release_fire", "event_patch": {"salvo_release_fire": true}}
	if semantic == "release_web":
		return {"route": "web_tether", "event_patch": {}}
	if semantic == "release_missile_lock":
		return {"route": "missile_lock", "event_patch": {"aim_locked": true}}
	if semantic == "release_lock":
		return {"route": "true_bullet_lock", "event_patch": {"aim_locked": true}}
	return {"route": "clear_pose", "event_patch": {}}


func release_lock_event_patch(route: String, event: Dictionary, locked_direction: Vector2, default_lock_seconds: float = 1.0) -> Dictionary:
	var route_key := route.to_lower()
	if not route_key in ["missile_lock", "true_bullet_lock"]:
		return {}
	var direction := locked_direction
	if direction.length() <= 0.01 and event.get("direction", Vector2.ZERO) is Vector2:
		direction = event.get("direction", Vector2.ZERO)
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	var patch := {
		"aim_locked": true,
		"direction": direction.normalized(),
	}
	if route_key == "true_bullet_lock":
		patch["bullet_lock_time"] = float(event.get("sniper_fire_delay", event.get("bullet_lock_time", default_lock_seconds)))
	return patch


func activation_state_payload(context: Dictionary) -> Dictionary:
	var mobility_contract := _dict(context.get("mobility_contract", {}))
	return {
		"prefix": String(context.get("prefix", "")),
		"attack_index": int(context.get("attack_index", -1)),
		"action_name": String(context.get("action_name", "")),
		"binding": _dict(context.get("binding", {})).duplicate(true),
		"locked_target": null,
		"locked_direction": Vector2.ZERO,
		"aim_direction": Vector2(context.get("aim_direction", Vector2.ZERO)),
		"gun_rotate_speed": float(context.get("gun_rotate_speed", 0.0)),
		"gun_kind": String(context.get("gun_kind", "")),
		"effective_gun_activation_profile": String(context.get("effective_gun_activation_profile", "")),
		"activation_semantic": String(context.get("activation_semantic", "")),
		"aim_input_mode": String(context.get("aim_input_mode", "")),
		"move_while_firing": bool(mobility_contract.get("move_while_firing", false)),
		"direction_boost_while_firing": bool(mobility_contract.get("direction_boost_while_firing", false)),
		"fire_timer": 0.0,
		"hold_time": 0.0,
	}
