extends RefCounted
class_name BattleActionEventService


func begin_module_action_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("unit_live", false)):
		return {"action": "none", "reason": "unit_gone"}
	return {
		"action": "begin",
		"module_key": String(context.get("module_key", "")),
		"attack_index": int(context.get("attack_index", 0)),
		"requires_joint_pair": bool(context.get("requires_joint_pair", false)),
	}


func runtime_attack_button_intent(context: Dictionary) -> Dictionary:
	var attack_index := int(context.get("attack_index", 0))
	var requested_state := String(context.get("requested_state", "normal"))
	if not bool(context.get("direct_runtime_topology", false)):
		return {"action": "legacy_attack", "attack_index": attack_index, "requested_state": requested_state}
	if bool(context.get("gun_activation", false)):
		return {"action": "start_gun_activation", "attack_index": attack_index, "requested_state": requested_state}
	if bool(context.get("held_melee_activation", false)):
		return {"action": "start_held_melee_activation", "attack_index": attack_index, "requested_state": requested_state}
	if bool(context.get("has_attack_window", false)):
		return {"action": "resolve_command_window", "attack_index": attack_index, "action_state": "normal"}
	if bool(context.get("binding_empty", false)):
		return {"action": "fail_unbound", "attack_index": attack_index}
	return {"action": "open_command_window", "attack_index": attack_index}


func explicit_gun_activation_event(event: Dictionary, profile_known: bool) -> bool:
	if profile_known:
		return true
	return bool(event.get("gun_activation", false)) and profile_known


func attack_button_command_state_intent(requested_state: String, module_action_profile: String) -> Dictionary:
	if not (requested_state in ["active", "armor"]):
		return {
			"action": "none",
			"requested_state": requested_state,
			"clear_buffer": false,
			"consume_melee_state": false,
		}
	if module_action_profile == "two_link_forward_snap":
		return {
			"action": "clear_buffer",
			"requested_state": requested_state,
			"clear_buffer": true,
			"consume_melee_state": false,
		}
	return {
		"action": "consume_melee_state",
		"requested_state": requested_state,
		"clear_buffer": false,
		"consume_melee_state": true,
	}


func attack_button_aim_mode(fallback_mode: String, true_bullet: bool) -> String:
	if true_bullet:
		return "manual"
	if fallback_mode == "":
		return "fixed"
	return fallback_mode


func hold_activation_initial_delay(hold_to_activate: bool, projectile: bool, release_to_fire: bool, true_bullet: bool) -> float:
	if not hold_to_activate or not projectile:
		return 0.0
	if release_to_fire or true_bullet:
		return 9999.0
	return 0.0


func hold_activation_fire_interval(context: Dictionary) -> float:
	var fire_rate := float(context.get("fire_rate", 0.0))
	if fire_rate > 0.0:
		return 1.0 / maxf(0.05, fire_rate)
	var fire_interval := float(context.get("fire_interval", 0.0))
	if fire_interval > 0.0:
		return maxf(0.04, fire_interval)
	var damage_type := String(context.get("damage_type", ""))
	if damage_type == "laser":
		var default_aim := float(context.get("laser_default_aim_seconds", 0.46))
		var min_aim := float(context.get("laser_min_aim_seconds", 0.18))
		var max_aim := float(context.get("laser_max_aim_seconds", 1.1))
		return clampf(float(context.get("laser_aim_time", default_aim)), min_aim, max_aim) + 0.32
	if damage_type == "chemical":
		return 0.2
	if String(context.get("projectile_behavior", "")) == "bullet_hell":
		return 0.16
	return 0.24


func hold_activation_fire_intent(true_bullet_aim: bool, hold_to_activate: bool, projectile: bool, current_timer: float, delta: float, fire_interval: float) -> Dictionary:
	if true_bullet_aim or not hold_to_activate or not projectile:
		return {
			"action": "none",
			"timer": current_timer,
			"fire": false,
		}
	var next_timer := current_timer - delta
	if next_timer > 0.0:
		return {
			"action": "wait",
			"timer": next_timer,
			"fire": false,
		}
	return {
		"action": "fire",
		"timer": fire_interval,
		"fire": true,
	}


func held_aim_release_intent(release_to_fire: bool, hold_to_activate: bool, true_bullet: bool) -> Dictionary:
	var should_fire := release_to_fire or not hold_to_activate or true_bullet
	return {
		"action": "fire" if should_fire else "clear",
		"fire": should_fire,
	}


func command_token_vector(token: String) -> Vector2:
	match token:
		"1":
			return Vector2(-1.0, 1.0)
		"2":
			return Vector2.DOWN
		"3":
			return Vector2(1.0, 1.0)
		"4":
			return Vector2.LEFT
		"6":
			return Vector2.RIGHT
		"7":
			return Vector2(-1.0, -1.0)
		"8":
			return Vector2.UP
		"9":
			return Vector2(1.0, -1.0)
	return Vector2.ZERO


func latest_command_direction(buffer: Array) -> Vector2:
	for i in range(buffer.size() - 1, -1, -1):
		var direction := command_token_vector(String(buffer[i]))
		if direction.length() > 0.01:
			return direction.normalized()
	return Vector2.ZERO


func command_text(buffer: Array) -> String:
	var text := ""
	for token in buffer:
		text += str(token)
	return text


func command_buffer_record_intent(buffer: Array, timer: float, delta: float, direction_pressed: Dictionary, timeout: float = 0.42, max_tokens: int = 8) -> Dictionary:
	var next_timer := maxf(0.0, timer - maxf(0.0, delta))
	var next_buffer := buffer.duplicate(true)
	if next_timer <= 0.0:
		next_buffer = []
	var added_input := false
	for direction in [
		{"key": "down", "token": "2"},
		{"key": "right", "token": "6"},
		{"key": "left", "token": "4"},
		{"key": "up", "token": "8"},
	]:
		if bool(direction_pressed.get(String(direction["key"]), false)):
			next_buffer.append(String(direction["token"]))
			added_input = true
	if added_input:
		next_timer = maxf(0.0, timeout)
	while next_buffer.size() > max_tokens:
		next_buffer.pop_front()
	return {"buffer": next_buffer, "timer": next_timer, "added_input": added_input}


func command_match_intent(text: String, command: String) -> Dictionary:
	var aliases := {
		"236": ["236", "26"],
		"214": ["214", "24"],
		"632146": ["632146", "6246"],
	}
	var candidates: Array = Array(aliases.get(command, [command]))
	var matched := _text_matches_any(text, candidates)
	return {"matched": matched, "clear_buffer": matched, "candidates": candidates}


func command_skill_action_kind(requested_state: String, stats: Dictionary) -> String:
	var action_kind := requested_state if requested_state in ["active", "armor"] else String(stats.get("skill_state", "active"))
	var module_state := String(stats.get("module_state", ""))
	if module_state in ["active", "armor"]:
		action_kind = module_state
	return action_kind


func normal_attack_action_kind(requested_state: String) -> String:
	if requested_state in ["active", "armor"]:
		return requested_state
	return "normal"


func attack_direction(input_vector: Vector2, forward_vector: Vector2) -> Vector2:
	if input_vector.length() >= 0.2:
		return input_vector.normalized()
	return _normalized_or(forward_vector, Vector2.RIGHT)


func attack_direction_for_group(input_vector: Vector2, forward_vector: Vector2, group: Dictionary) -> Vector2:
	if input_vector.length() >= 0.2:
		return input_vector.normalized()
	var forward := _normalized_or(forward_vector, Vector2.RIGHT)
	var lane_bias := float(group.get("lane_bias", 0.0))
	var side := Vector2(-forward.y, forward.x)
	return _normalized_or(forward + side * lane_bias, forward)


func paired_attack_direction(input_vector: Vector2, forward_vector: Vector2, group: Dictionary, pair_index: int, _pair_count: int) -> Vector2:
	if String(group.get("paired_motion", "")) != "inward_clamp":
		return attack_direction_for_group(input_vector, forward_vector, group)
	var forward := _normalized_or(forward_vector, Vector2.RIGHT)
	var side := Vector2(-forward.y, forward.x)
	var lane_bias := float(group.get("lane_bias", 0.0))
	var inward_sign := -signf(lane_bias)
	if inward_sign == 0.0:
		inward_sign = 1.0 if pair_index % 2 == 0 else -1.0
	var clamp_weight := clampf(float(group.get("clamp_close_angle_degrees", 120.0)) / 180.0, 0.28, 0.95)
	var direction := _normalized_or(forward * (1.0 - clamp_weight * 0.38) + side * inward_sign * clamp_weight, forward)
	if input_vector.length() >= 0.2:
		direction = _normalized_or(direction.lerp(input_vector.normalized(), 0.18), direction)
	return direction


func runtime_module_direction(input_vector: Vector2, forward_vector: Vector2) -> Vector2:
	if input_vector.length() >= 0.18:
		return input_vector.normalized()
	return _normalized_or(forward_vector, Vector2.RIGHT)


func recoil_countered(boost_momentum: float, held_vector: Vector2, attack_direction: Vector2) -> bool:
	if boost_momentum <= 0.0:
		return false
	if held_vector.length() < 0.2:
		return false
	return held_vector.normalized().dot(-attack_direction.normalized()) > 0.55


func facing_relative_attack_state(input_vector: Vector2, latest_direction: Vector2, forward_vector: Vector2) -> String:
	var command_direction := input_vector
	if command_direction.length() < 0.18:
		command_direction = latest_direction
	return _relative_attack_state(command_direction, forward_vector)


func two_link_forward_snap_attack_state(input_vector: Vector2, latest_direction: Vector2, forward_vector: Vector2) -> String:
	var command_direction := input_vector
	if command_direction.length() < 0.18:
		command_direction = latest_direction
	return _relative_attack_state(command_direction, forward_vector)


func attack_state_for_group(profile: String, input_vector: Vector2, latest_direction: Vector2, forward_vector: Vector2, fallback_state: String) -> String:
	if profile == "two_link_forward_snap":
		return two_link_forward_snap_attack_state(input_vector, latest_direction, forward_vector)
	return fallback_state


func melee_command_attack_intent(input_vector: Vector2, latest_direction: Vector2, forward_vector: Vector2, consume: bool = true) -> Dictionary:
	var attack_state := facing_relative_attack_state(input_vector, latest_direction, forward_vector)
	return {
		"attack_state": attack_state,
		"clear_buffer": consume and attack_state in ["active", "armor"],
	}


func consume_melee_state_intent(input_vector: Vector2, latest_direction: Vector2, forward_vector: Vector2, requested_state: String) -> Dictionary:
	var attack_state := facing_relative_attack_state(input_vector, latest_direction, forward_vector)
	var matched := attack_state == requested_state
	return {
		"attack_state": attack_state,
		"matched": matched,
		"clear_buffer": matched,
	}


func command_window_route_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("has_window", false)):
		return {"action": "none"}
	var state := String(context.get("action_state", "normal"))
	if state == "":
		state = "normal"
	return {
		"action": "fire",
		"attack_index": int(context.get("attack_index", 0)),
		"action_state": state,
		"close_window": true,
	}


func command_window_resolve_all_intent(window_entries: Array) -> Dictionary:
	var resolved_entries: Array = []
	for raw_entry in window_entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var state := String(entry.get("state", ""))
		if state == "":
			continue
		var attack_index := int(entry.get("attack_index", String(entry.get("window_key", "0")).to_int()))
		resolved_entries.append({
			"window_key": String(entry.get("window_key", attack_index)),
			"attack_index": attack_index,
			"state": state,
		})
	if resolved_entries.is_empty():
		return {"action": "none", "entries": [], "close_window_keys": []}
	resolved_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("attack_index", 0)) < int(b.get("attack_index", 0))
	)
	var close_window_keys: Array = []
	for entry in resolved_entries:
		close_window_keys.append(String(entry.get("window_key", "")))
	return {"action": "fire_all", "entries": resolved_entries, "close_window_keys": close_window_keys}


func command_window_tick_intent(window: Dictionary, action_pressed: bool, delta: float, timeout: float, hold_cancel_seconds: float) -> Dictionary:
	var next_window := window.duplicate(true)
	var step := maxf(0.0, delta)
	next_window["timer"] = float(next_window.get("timer", timeout)) - step
	if action_pressed:
		next_window["hold_time"] = float(next_window.get("hold_time", 0.0)) + step
	else:
		next_window["hold_time"] = 0.0
	if float(next_window.get("hold_time", 0.0)) >= maxf(0.0, hold_cancel_seconds):
		return {"action": "cancel", "window": next_window}
	if float(next_window.get("timer", 0.0)) <= 0.0:
		return {"action": "expire", "window": next_window}
	return {"action": "keep", "window": next_window}


func command_window_text_state(profile: String, text: String) -> String:
	match profile:
		"blade_simple_4_6":
			if _text_matches_any(text, ["6"]):
				return "armor"
			if _text_matches_any(text, ["4"]):
				return "active"
		"blade_complex_236_214", "gauntlet_4_6_236_214", "blunt_terminal_4_6_236_214":
			if _text_matches_any(text, ["236", "26"]):
				return "armor"
			if _text_matches_any(text, ["214", "24"]):
				return "active"
	return ""


func command_window_blade_variant(profile: String, text: String, action_state: String) -> String:
	var text_state := command_window_text_state(profile, text)
	match profile:
		"blade_simple_4_6":
			if text_state == "armor" or action_state == "armor":
				return "armor_forward_cut"
			if text_state == "active" or action_state == "active":
				return "active_reverse_cut"
		"blade_complex_236_214":
			if text_state == "armor" or action_state == "armor":
				return "armor_special"
			if text_state == "active" or action_state == "active":
				return "active_special"
	return "normal_sweep"


func command_window_gauntlet_variant(text: String, action_state: String, input_vector: Vector2, latest_direction: Vector2, forward_vector: Vector2) -> String:
	var text_state := command_window_text_state("gauntlet_4_6_236_214", text)
	if text_state == "armor" or action_state == "armor":
		return "armor_inward_extend"
	if text_state == "active" or action_state == "active":
		return "active_outward_extend"
	var command_direction := input_vector
	if command_direction.length() < 0.18:
		command_direction = latest_direction
	if command_direction.length() >= 0.18 and forward_vector.length() >= 0.01:
		var dot := command_direction.normalized().dot(forward_vector.normalized())
		if dot >= 0.38:
			return "normal_inward_swing"
		if dot <= -0.38:
			return "normal_outward_swing"
	return "normal_extend"


func command_window_blunt_variant(profile: String, text: String, action_state: String, input_vector: Vector2, latest_direction: Vector2, forward_vector: Vector2) -> String:
	var text_state := command_window_text_state("blunt_terminal_4_6_236_214", text)
	var command_direction := input_vector
	if command_direction.length() < 0.18:
		command_direction = latest_direction
	if profile == "blunt_shield_guard_bash":
		if text_state == "armor" or action_state == "armor":
			return "armor_guard_bash"
		if text_state == "active" or action_state == "active":
			return "active_shoulder_bash"
		if command_direction.length() >= 0.18 and forward_vector.length() >= 0.01:
			var shield_dot := command_direction.normalized().dot(forward_vector.normalized())
			if shield_dot >= 0.38:
				return "normal_forward_bash"
			if shield_dot <= -0.38:
				return "normal_back_bash"
		return "normal_guard"
	if text_state == "armor" or action_state == "armor":
		return "armor_overhead_slam"
	if text_state == "active" or action_state == "active":
		return "active_side_slam"
	if command_direction.length() >= 0.18 and forward_vector.length() >= 0.01:
		var hammer_dot := command_direction.normalized().dot(forward_vector.normalized())
		if hammer_dot >= 0.38:
			return "normal_forward_slam"
		if hammer_dot <= -0.38:
			return "normal_back_slam"
	return "normal_short_swing"


func command_window_binding_profile(binding: Dictionary) -> Dictionary:
	var module_part: Dictionary = binding.get("module_part", {}) if binding.get("module_part", {}) is Dictionary else {}
	return {
		"profile": String(binding.get("module_action_profile", module_part.get("module_action_profile", ""))),
		"command_profile": String(binding.get("command_window_profile", module_part.get("command_window_profile", ""))),
	}


func command_window_should_clear_buffer(action_state: String, runtime_profile: String, command_profiles: Array = []) -> bool:
	if action_state in ["active", "armor"]:
		return true
	return command_profiles.has(runtime_profile)


func command_window_runtime_state(runtime_profile: String, command_window_profile: String, text: String, fallback_state: String, gauntlet_profiles: Array = [], blunt_profiles: Array = [], blade_profiles: Array = []) -> String:
	var text_state := ""
	if gauntlet_profiles.has(runtime_profile):
		text_state = command_window_text_state("gauntlet_4_6_236_214", text)
	elif blunt_profiles.has(runtime_profile):
		text_state = command_window_text_state("blunt_terminal_4_6_236_214", text)
	elif blade_profiles.has(runtime_profile):
		text_state = command_window_text_state(command_window_profile, text)
	if text_state != "":
		return text_state
	return fallback_state


func command_window_runtime_variant(runtime_profile: String, command_window_profile: String, text: String, action_state: String, input_vector: Vector2, latest_direction: Vector2, forward_vector: Vector2, gauntlet_profiles: Array = [], blunt_profiles: Array = [], blade_profiles: Array = []) -> String:
	if gauntlet_profiles.has(runtime_profile):
		return command_window_gauntlet_variant(text, action_state, input_vector, latest_direction, forward_vector)
	if blunt_profiles.has(runtime_profile):
		return command_window_blunt_variant(runtime_profile, text, action_state, input_vector, latest_direction, forward_vector)
	if blade_profiles.has(runtime_profile):
		return command_window_blade_variant(command_window_profile, text, action_state)
	return ""


func command_window_state_for_input(input_vector: Vector2, forward_vector: Vector2) -> String:
	if input_vector.length() < 0.18:
		return ""
	if forward_vector.length() < 0.01:
		return ""
	var dot := input_vector.normalized().dot(forward_vector.normalized())
	if dot >= 0.38:
		return "armor"
	if dot <= -0.38:
		return "active"
	return ""


func command_window_state_for_binding(binding: Dictionary, input_vector: Vector2, forward_vector: Vector2, eligible_profiles: Array = []) -> String:
	var module_part := _dict(binding.get("module_part", {}))
	var profile := String(binding.get("command_window_profile", module_part.get("command_window_profile", "")))
	if not eligible_profiles.has(profile):
		return ""
	return command_window_state_for_input(input_vector, forward_vector)


func module_event_patch(context: Dictionary) -> Dictionary:
	var event := _dict(context.get("event", {})).duplicate(true)
	var group := _dict(context.get("group", {}))
	var stats := _dict(context.get("stats", {}))
	var direction := _normalized_or(_vec(context.get("direction", Vector2.RIGHT)), Vector2.RIGHT)
	var attack_index := int(context.get("attack_index", 0))
	var fallback_names: Array = Array(context.get("attack_group_fallback", []))
	event["direction"] = direction
	if context.has("locked_target"):
		event["locked_target"] = context.get("locked_target", null)
	event["muscle_node"] = attack_index
	event["collision_group"] = group.duplicate(true)
	event["group_name"] = String(group.get("name", _fallback_group_name(fallback_names, attack_index)))
	event["damage_type"] = String(group.get("damage_type", event.get("damage_type", "blunt")))
	event["material_class"] = String(group.get("melee_contact_class", group.get("material_class", "weapon")))
	var state_key := String(event.get("state", "normal"))
	var override_key := "%s_damage_override" % state_key
	var base_damage := float(event.get("damage", 1.0))
	if group.has(override_key):
		base_damage = float(group[override_key])
	event["damage"] = int(roundf(base_damage * float(group.get("damage_mult", 1.0))))
	event["range"] = float(event.get("range", 0.3)) * float(group.get("range_mult", 1.0)) + _damage_type_range_bonus(stats, String(event.get("damage_type", "blunt")))
	event["lane_range"] = float(event.get("lane_range", 0.2)) * float(group.get("lane_mult", 1.0))
	event["recoil"] = float(event.get("recoil", 0.06)) * float(group.get("recoil_mult", 1.0))
	if bool(context.get("projectile", group.get("projectile", stats.get("projectile", false)))):
		event = _apply_projectile_module_fields(event, group, context)
	return {"event": event, "state_key": state_key, "base_damage": base_damage}


func runtime_direct_module_event_patch(context: Dictionary) -> Dictionary:
	var event := _dict(context.get("event", {})).duplicate(true)
	var module_part := _dict(context.get("module_part", {}))
	var action_state := String(context.get("action_state", event.get("state", "normal")))
	event["direction"] = _normalized_or(_vec(context.get("direction", Vector2.RIGHT)), Vector2.RIGHT)
	event["group_name"] = String(module_part.get("name", "ACTION MODULE"))
	event["damage_type"] = String(module_part.get("damage_type", event.get("damage_type", "blunt")))
	event["material_class"] = String(module_part.get("material_class", event.get("material_class", "weapon")))
	event["weapon_damage_coeff"] = float(context.get("weapon_damage_coeff", 1.0))
	event["fixed_output_momentum"] = float(module_part.get("fixed_output_momentum", module_part.get("joint_output_momentum", 0.0)))
	event["runtime_direct_module"] = true
	return {"event": event, "state_label": String(event.get("state", action_state)).to_upper()}


func control_event_fields_patch(event: Dictionary, group: Dictionary) -> Dictionary:
	var patched := event.duplicate(true)
	for event_key in [
		"non_damage",
		"web_strength",
		"web_break_force",
		"web_pull_mode",
		"blind_radius",
		"blind_duration",
		"blind_strength",
		"takeover_on_hit",
		"takeover_seconds",
		"takeover_power",
		"takeover_damage_rate",
		"takeover_damage_type",
		"explosion_radius",
		"explosion_damage_type",
		"explosion_style",
		"back_hit_heat_bonus",
		"back_hit_heat_mult",
		"laser_aim_time",
		"projectile_behavior",
		"projectile_momentum",
		"projectile_base_momentum",
		"projectile_effective_momentum",
		"projectile_drive_momentum_mult",
		"projectile_mass",
		"projectile_collision_speed",
		"projectile_speed_mult",
		"gun_projectile_damage_mult",
		"gun_projectile_damage_mult_current",
		"gun_drive_allocated",
		"gun_drive_min",
		"gun_drive_max",
		"gun_drive_ratio",
		"gun_drive_ratio_to_max",
		"fire_rate",
		"fire_interval",
		"carried_ammo",
		"ammo_capacity",
		"bullet_lock_time",
		"bullet_lock_radius",
		"chemical_dot_duration",
		"chemical_dot_mult",
		"chemical_frontload",
		"chemical_pellets",
		"chemical_spread",
		"missile_lock_priority",
		"missile_lock_cone_degrees",
		"missile_lock_range",
		"missile_lock_target_classes",
		"missile_occlusion_grace",
	]:
		if group.has(event_key):
			patched[event_key] = group[event_key]
	if bool(patched.get("non_damage", false)):
		patched["damage"] = 0
	return patched


func module_variant_event_patch(event: Dictionary, module_part: Dictionary) -> Dictionary:
	var patched := event.duplicate(true)
	var variant_key := String(module_part.get("module_variant_key", "")).to_lower()
	if variant_key == "":
		return patched
	patched["module_variant_key"] = variant_key
	patched["module_visual_family"] = String(module_part.get("module_visual_family", variant_key))
	patched["module_variant_label"] = String(module_part.get("module_variant_label", ""))
	match variant_key:
		"balance_string":
			patched["combo_balance_window"] = float(module_part.get("combo_balance_window", 1.2))
			patched["combo_balance_cooldown_mult"] = float(module_part.get("combo_balance_cooldown_mult", 0.62))
		"vise_close":
			patched["clamp_pin_seconds"] = float(module_part.get("clamp_pin_seconds", 0.38))
			patched["clamp_velocity_mult"] = float(module_part.get("clamp_velocity_mult", 0.35))
			patched["clamp_knock_mult"] = float(module_part.get("clamp_knock_mult", 0.38))
			patched["knock"] = float(patched.get("knock", 0.12)) * clampf(float(module_part.get("clamp_knock_mult", 0.38)), 0.05, 1.0)
		"pickup_dash":
			patched["pickup_dash_impulse"] = float(module_part.get("pickup_dash_impulse", 0.65))
			patched["pickup_dash_on_hit_impulse"] = float(module_part.get("pickup_dash_on_hit_impulse", 0.35))
			patched["route_lane_pull"] = float(module_part.get("route_lane_pull", 0.1))
		"crush_windup":
			patched["contact_momentum_mult"] = float(module_part.get("crush_contact_momentum_mult", 1.45))
			patched["crush_stagger_mult"] = float(module_part.get("crush_stagger_mult", 1.35))
			patched["whiff_recovery_mult"] = float(module_part.get("whiff_recovery_mult", 1.25))
			patched["runtime_contact_damage_mult"] = float(module_part.get("runtime_contact_damage_mult", 1.24))
		"feint_thrust":
			patched["feint_retarget_degrees"] = float(module_part.get("feint_retarget_degrees", 18.0))
			patched["feint_ghost_phase"] = float(module_part.get("feint_ghost_phase", 0.42))
			patched["feint_final_width_mult"] = float(module_part.get("feint_final_width_mult", 0.65))
		"explosive_arc_salvo":
			patched["salvo_arc_min_range"] = float(module_part.get("salvo_arc_min_range", 1.35))
			patched["salvo_arc_max_range"] = float(module_part.get("salvo_arc_max_range", 3.8))
			patched["salvo_hold_range_seconds"] = float(module_part.get("salvo_hold_range_seconds", 0.75))
			patched["salvo_landing_marker"] = bool(module_part.get("salvo_landing_marker", true))
	return patched


func module_effect_event_patch(event: Dictionary, group: Dictionary) -> Dictionary:
	var patched := event.duplicate(true)
	var module_effect := String(group.get("module_effect", ""))
	patched["module_effect"] = module_effect
	patched["travel_path"] = String(group.get("travel_path", patched.get("travel_path", "straight")))
	if module_effect in ["eject", "chain_recall", "capture", "tether", "entangle", "barrier_break", "boomerang_recall", "guided_eject", "group_throw", "throw_guidance", "web_anchor", "web_reel", "web_tether", "light_sink"]:
		patched["projectile"] = true
		patched["range"] = maxf(float(patched.get("range", 0.5)), float(group.get("module_range", 1.4)))
		patched["lane_range"] = maxf(float(patched.get("lane_range", 0.24)), float(group.get("module_lane_range", 0.34)))
		patched["projectile_style"] = String(group.get("projectile_style", module_effect))
		patched["state"] = String(group.get("module_state", patched.get("state", "normal")))
		patched["damage"] = int(roundf(float(patched.get("damage", 1)) * float(group.get("module_damage_mult", 1.0))))
	patched = control_event_fields_patch(patched, group)
	if module_effect in ["web_anchor", "web_reel", "web_tether", "light_sink"] or bool(patched.get("non_damage", false)):
		patched["non_damage"] = true
		patched["damage"] = 0
	if module_effect == "chaos_shot":
		patched["projectile"] = true
		patched["projectile_style"] = "chaos"
		patched["travel_path"] = "instant_line"
		patched["range"] = maxf(float(patched.get("range", 0.5)), 4.15)
		patched["lane_range"] = maxf(float(patched.get("lane_range", 0.24)), 0.18)
		patched["damage"] = int(roundf(float(patched.get("damage", 1)) * 0.82))
	return patched


func gun_activation_event_patch(context: Dictionary) -> Dictionary:
	var event := _dict(context.get("event", {})).duplicate(true)
	var group := _dict(context.get("group", {}))
	var spec := _dict(context.get("spec", {}))
	var module_part := _dict(context.get("module_part", {}))
	var state := _dict(context.get("state", {}))
	var constants := _dict(context.get("constants", {}))
	var gun_kind := String(context.get("gun_kind", group.get("gun_kind", "")))
	var ammo_kind := String(context.get("ammo_kind", group.get("ammo_kind", "")))
	var projectile_damage_type := String(spec.get("projectile_damage_type", group.get("projectile_damage_type", group.get("damage_type", "bullet"))))
	var projectile_style := String(spec.get("projectile_style", group.get("projectile_style", "true_bullet")))
	var projectile_behavior := String(spec.get("projectile_behavior", group.get("projectile_behavior", projectile_style)))
	var default_width := float(spec.get("default_width", constants.get("standard_sniper_projectile_width_m", 0.1)))
	event["gun_kind"] = gun_kind
	event["ammo_kind"] = ammo_kind
	event["projectile_momentum"] = maxf(float(group.get("projectile_momentum", 0.0)), float(event.get("projectile_momentum", 0.0)))
	if float(event.get("projectile_momentum", 0.0)) <= 0.0:
		event["projectile_momentum"] = maxf(1.0, float(group.get("normal_damage", 8.0)) * 3.5)
	event["projectile_damage_type"] = projectile_damage_type
	event["damage_type"] = String(event.get("projectile_damage_type", "bullet"))
	event["projectile_style"] = projectile_style
	event["projectile_behavior"] = projectile_behavior
	event["travel_path"] = String(spec.get("travel_path", group.get("travel_path", "instant_line")))
	event["projectile_width_m"] = float(group.get("projectile_width_m", default_width))
	event["projectile_break_coeff"] = float(group.get("projectile_break_coeff", 0.0))
	event["projectile_consumes_on_fire"] = bool(group.get("projectile_consumes_on_fire", true))
	event["gun_drive_allocated"] = float(group.get("gun_drive_allocated", 0.0))
	event["gun_drive_min"] = float(group.get("gun_drive_min", 0.0))
	event["gun_drive_max"] = float(group.get("gun_drive_max", 0.0))
	event["gun_drive_ratio"] = float(group.get("gun_drive_ratio", 1.0))
	event["gun_drive_ratio_to_max"] = float(group.get("gun_drive_ratio_to_max", 1.0))
	event["gun_projectile_damage_mult"] = float(context.get("gun_projectile_damage_mult", group.get("gun_projectile_damage_mult", 0.0)))
	event["gun_projectile_damage_mult_current"] = float(context.get("gun_projectile_damage_mult_current", group.get("gun_projectile_damage_mult_current", 0.0)))
	event["normal_heat"] = float(group.get("normal_heat", 0.0))
	event["sniper_fire_delay"] = float(group.get("sniper_fire_delay", group.get("bullet_lock_time", constants.get("true_bullet_default_lock_seconds", 1.0))))
	event["bullet_lock_time"] = event["sniper_fire_delay"]
	event["fire_interval"] = maxf(0.04, float(group.get("laser_tick_interval", group.get("fire_interval", spec.get("default_fire_interval", 0.24)))))
	var semantic := String(spec.get("semantic", ""))
	var laser_visible_range := float(context.get("laser_visible_range", 0.0))
	match semantic:
		"hold_stream":
			event["range"] = maxf(0.1, float(group.get("projectile_range", group.get("range", spec.get("default_range", constants.get("standard_chemical_sprayer_range_m", 1.6))))))
			event["lane_range"] = maxf(0.01, float(event.get("projectile_width_m", default_width)) * 0.5)
			event["chemical_dot_duration"] = float(group.get("chemical_dot_duration", constants.get("standard_chemical_sprayer_dot_seconds", 1.2)))
			event["chemical_dot_mult"] = float(group.get("chemical_dot_mult", 1.0))
			event["chemical_frontload"] = float(group.get("chemical_frontload", 1.0 / 3.0))
			event["chemical_dot_tick_seconds"] = float(group.get("chemical_dot_tick_seconds", constants.get("standard_chemical_sprayer_tick_seconds", 0.35)))
			event["chemical_dot_no_stack"] = bool(group.get("chemical_dot_no_stack", true))
			event["projectile_speed_mult"] = float(group.get("projectile_speed_mult", constants.get("chemical_projectile_default_speed_mult", 0.72)))
		"hold_beam":
			event["range"] = maxf(float(group.get("projectile_range", constants.get("standard_laser_range_m", 4.2))), laser_visible_range)
			event["lane_range"] = maxf(0.01, float(event.get("projectile_width_m", constants.get("standard_laser_width_m", 0.18))) * 0.5)
			event["laser_telegraph_ready"] = true
			event["laser_charge_time"] = float(group.get("laser_charge_time", 0.0))
		"hold_burst":
			event["range"] = maxf(0.1, float(group.get("projectile_range", group.get("range", 2.8))))
			event["lane_range"] = maxf(0.01, float(event.get("projectile_width_m", default_width)) * 0.5)
			event["projectile_speed_mult"] = float(group.get("projectile_speed_mult", constants.get("bullet_hell_default_speed_mult", 2.8)))
		"hold_grenade_arc":
			event["range"] = maxf(0.1, float(group.get("projectile_range", group.get("range", spec.get("default_range", 2.65)))))
			if String(event.get("module_variant_key", "")) == "explosive_arc_salvo":
				var hold_seconds := maxf(0.05, float(event.get("salvo_hold_range_seconds", 0.75)))
				var hold_t := clampf(float(state.get("hold_time", 0.0)) / hold_seconds, 0.0, 1.0)
				var min_range := maxf(0.1, float(event.get("salvo_arc_min_range", 1.35)))
				var max_range := maxf(min_range, float(event.get("salvo_arc_max_range", 3.8)))
				event["range"] = lerpf(min_range, max_range, hold_t)
				event["salvo_hold_ratio"] = hold_t
				event["salvo_landing_marker"] = true
				event["salvo_landing_distance"] = float(event["range"])
			event["lane_range"] = maxf(0.01, float(event.get("projectile_width_m", default_width)) * 0.5)
			event["projectile_speed_mult"] = float(group.get("projectile_speed_mult", 1.35))
			event["projectile_momentum"] = maxf(float(group.get("projectile_momentum", 72.0)), float(event.get("projectile_momentum", 0.0)))
			event["explosion_radius"] = maxf(0.01, float(group.get("explosion_radius", 0.56)))
			event["explosion_style"] = String(group.get("explosion_style", "grenade"))
		"release_web":
			event["range"] = maxf(0.1, float(group.get("projectile_range", group.get("range", spec.get("default_range", constants.get("standard_web_tether_range_m", 4.4))))))
			event["lane_range"] = maxf(0.01, float(event.get("projectile_width_m", default_width)) * 0.5)
			event["non_damage"] = true
			event["web_strength"] = maxf(0.01, float(group.get("web_strength", constants.get("standard_web_tether_strength", 0.34))))
			event["web_break_force"] = maxf(0.08, float(group.get("web_break_force", constants.get("standard_web_tether_break_force", 1.08))))
			event["web_duration"] = maxf(0.1, float(group.get("web_duration", constants.get("standard_web_tether_duration", 1.6))))
			event["web_pull_mode"] = String(group.get("web_pull_mode", "mass_duel"))
			event["web_target_filter"] = String(group.get("web_target_filter", "all"))
			event["web_anchor_swing"] = bool(group.get("web_anchor_swing", true))
			event["web_swing_uses_melee_collision"] = bool(group.get("web_swing_uses_melee_collision", true))
		"release_missile_lock":
			event["range"] = maxf(0.1, float(group.get("projectile_range", group.get("range", spec.get("default_range", constants.get("standard_missile_range_m", 3.4))))))
			event["lane_range"] = maxf(0.01, float(event.get("projectile_width_m", default_width)) * 0.5)
			event["projectile_speed_mult"] = float(group.get("projectile_speed_mult", constants.get("standard_missile_speed_mult", 1.05)))
			event["projectile_momentum"] = maxf(float(group.get("projectile_momentum", constants.get("standard_missile_projectile_momentum", 92.0))), float(event.get("projectile_momentum", 0.0)))
			event["explosion_radius"] = maxf(0.01, float(group.get("explosion_radius", constants.get("standard_missile_explosion_radius", 0.64))))
			event["explosion_style"] = String(group.get("explosion_style", "missile"))
			event["missile_lock_priority"] = String(module_part.get("missile_lock_priority", group.get("missile_lock_priority", "screen_hero_first")))
			event["missile_lock_cone_degrees"] = float(module_part.get("missile_lock_cone_degrees", group.get("missile_lock_cone_degrees", 52.0)))
			event["missile_lock_range"] = maxf(0.1, float(group.get("missile_lock_range", event.get("range", constants.get("standard_missile_range_m", 3.4)))))
			event["missile_lock_target_classes"] = Array(group.get("missile_lock_target_classes", ["hero", "puppet", "barrier_support", "barrier_attack", "barrier_other"])).duplicate(true)
			event["missile_occlusion_grace"] = maxf(0.0, float(module_part.get("missile_occlusion_grace", group.get("missile_occlusion_grace", constants.get("standard_missile_occlusion_grace", 0.28)))))
		_:
			event["range"] = maxf(float(group.get("projectile_range", 0.0)), laser_visible_range)
			event["lane_range"] = maxf(float(constants.get("standard_sniper_projectile_width_m", 0.1)) * 0.5, float(event.get("projectile_width_m", constants.get("standard_sniper_projectile_width_m", 0.1))) * 0.5)
	return {"event": event, "semantic": semantic}


func _apply_projectile_module_fields(event: Dictionary, group: Dictionary, context: Dictionary) -> Dictionary:
	var constants := _dict(context.get("constants", {}))
	event["projectile"] = true
	event["material_class"] = "projectile"
	event["damage_type"] = String(group.get("projectile_damage_type", event.get("damage_type", "bullet")))
	event["projectile_style"] = String(group.get("projectile_style", context.get("projectile_style", "bullet")))
	event["projectile_behavior"] = String(context.get("projectile_behavior", group.get("projectile_behavior", event.get("projectile_style", "bullet"))))
	if String(event["projectile_behavior"]) == "bullet_hell":
		event["projectile_style"] = "bullet_hell"
		event["projectile_speed_mult"] = float(group.get("projectile_speed_mult", constants.get("bullet_hell_default_speed_mult", 2.8)))
	event["travel_path"] = String(group.get("travel_path", "straight"))
	event["range"] = maxf(float(event["range"]), float(group.get("projectile_range", 2.25)))
	if String(event["projectile_behavior"]) == "true_bullet":
		event["projectile_style"] = "true_bullet"
		event["travel_path"] = "instant_line"
		event["range"] = maxf(float(event["range"]), float(context.get("laser_visible_range", event["range"])))
	if String(event["projectile_style"]) == "missile":
		event["range"] = maxf(float(event["range"]), 3.2)
		event["lane_range"] = float(event.get("lane_range", 0.2)) + 0.18
		event["damage"] = int(roundf(float(event.get("damage", 1)) * 1.18))
	return event


func _damage_type_range_bonus(stats: Dictionary, damage_type: String) -> float:
	match damage_type:
		"pierce":
			return float(stats.get("pierce_range_bonus", 0.0))
		"tear":
			return float(stats.get("tear_range_bonus", 0.0))
	return 0.0


func _fallback_group_name(fallback_names: Array, attack_index: int) -> String:
	if attack_index >= 0 and attack_index < fallback_names.size():
		return String(fallback_names[attack_index])
	return "ATTACK"


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


func _relative_attack_state(command_direction: Vector2, forward_vector: Vector2) -> String:
	if command_direction.length() < 0.18:
		return "normal"
	if forward_vector.length() < 0.01:
		return "normal"
	var forward := forward_vector.normalized()
	var normalized := command_direction.normalized()
	var dot := normalized.dot(forward)
	if dot >= 0.38:
		return "armor"
	if dot <= -0.38:
		return "active"
	return "normal"


func _text_matches_any(text: String, candidates: Array) -> bool:
	for candidate in candidates:
		if text.ends_with(String(candidate)):
			return true
	return false
