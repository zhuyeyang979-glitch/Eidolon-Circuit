extends RefCounted
class_name HeldMeleeActivationService


func _dict(value) -> Dictionary:
	return value if value is Dictionary else {}


func _runtime_binding_profile(binding: Dictionary) -> String:
	var module_part := _dict(binding.get("module_part", {}))
	return String(binding.get("module_action_profile", module_part.get("module_action_profile", "")))


func runtime_binding_is_held_melee_activation(binding: Dictionary, held_profile: String) -> bool:
	if binding.is_empty():
		return false
	if _runtime_binding_profile(binding) != held_profile:
		return false
	var module_part := _dict(binding.get("module_part", {}))
	return bool(binding.get("hold_to_activate", module_part.get("hold_to_activate", true)))


func boot_driver_initial_state(input_vector: Vector2, forward_vector: Vector2) -> String:
	if input_vector.length() < 0.18:
		return "normal"
	if forward_vector.length() < 0.01:
		return "normal"
	var dot := input_vector.normalized().dot(forward_vector.normalized())
	if dot >= 0.38:
		return "armor"
	if dot <= -0.38:
		return "active"
	return "normal"


func held_activation_state_payload(context: Dictionary) -> Dictionary:
	var binding := _dict(context.get("binding", {}))
	var module_part := _dict(binding.get("module_part", {}))
	return {
		"prefix": String(context.get("prefix", "")),
		"attack_index": int(context.get("attack_index", -1)),
		"action_name": String(context.get("action_name", "")),
		"binding": binding.duplicate(true),
		"module_action_profile": String(context.get("profile", "")),
		"action_state": String(context.get("action_state", "normal")),
		"turn_keys_steer_joint": bool(binding.get("turn_keys_steer_joint", module_part.get("turn_keys_steer_joint", true))),
		"hold_time": 0.0,
	}


func turn_input_from_strengths(face_right_strength: float, face_left_strength: float, deadzone: float = 0.08) -> float:
	var turn_input := float(face_right_strength) - float(face_left_strength)
	if absf(turn_input) <= maxf(0.0, deadzone):
		return 0.0
	return clampf(turn_input, -1.0, 1.0)


func tick_state_payload(state: Dictionary, turn_input: float, delta: float) -> Dictionary:
	var next_state := state.duplicate(true)
	next_state["hold_time"] = maxf(0.0, float(next_state.get("hold_time", 0.0))) + maxf(0.0, delta)
	next_state["turn_input"] = clampf(float(turn_input), -1.0, 1.0)
	return next_state


func activation_state_active(state: Dictionary) -> bool:
	return not state.is_empty()


func held_turn_keys_reserved(state: Dictionary) -> bool:
	if state.is_empty():
		return false
	return bool(state.get("turn_keys_steer_joint", true))


func should_release_hold(action_name: String, action_just_released: bool, action_pressed: bool) -> bool:
	return action_name == "" or action_just_released or not action_pressed


func held_activation_event_payload(event: Dictionary) -> Dictionary:
	var payload := event.duplicate(true)
	payload["projectile"] = false
	payload["projectile_only"] = false
	payload["runtime_melee_contact"] = true
	payload["boot_driver_held_activation"] = true
	payload["damage_type"] = String(payload.get("damage_type", "blunt"))
	return payload


func activation_direction(binding: Dictionary, rotating_segment: Dictionary, fallback_forward: Vector2, input_vector: Vector2) -> Vector2:
	var direction := fallback_forward.normalized() if fallback_forward.length() > 0.01 else Vector2.ZERO
	var target_nodes: Array = Array(binding.get("target_nodes", []))
	if target_nodes.size() >= 2 and not rotating_segment.is_empty():
		var a: Vector2 = rotating_segment.get("a", Vector2.ZERO)
		var b: Vector2 = rotating_segment.get("b", a)
		var segment_dir := b - a
		if segment_dir.length() > 0.01:
			direction = segment_dir.normalized()
	if direction.length() <= 0.01:
		direction = input_vector.normalized() if input_vector.length() >= 0.18 else Vector2.ZERO
	return direction
