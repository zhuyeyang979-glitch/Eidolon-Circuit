extends RefCounted
class_name BattleInputService


func battle_action_names(prefixes: Array, attack_group_count: int) -> Array:
	var actions: Array = ["battle_pause"]
	for raw_prefix in prefixes:
		var prefix := String(raw_prefix)
		for suffix in ["left", "right", "up", "down", "face_left", "face_right", "portal"]:
			actions.append("%s_%s" % [prefix, suffix])
		for attack_index in range(maxi(0, attack_group_count)):
			actions.append("%s_attack_%d" % [prefix, attack_index + 1])
	return actions


func capture_edge_frame(action_names: Array, pending_pressed: Dictionary, pending_released: Dictionary, just_pressed_fn: Callable, just_released_fn: Callable) -> Dictionary:
	var pressed := pending_pressed.duplicate(true)
	var released := pending_released.duplicate(true)
	for raw_action in action_names:
		var action_name := String(raw_action)
		if just_pressed_fn.is_valid() and bool(just_pressed_fn.call(action_name)):
			pressed[action_name] = true
		if just_released_fn.is_valid() and bool(just_released_fn.call(action_name)):
			released[action_name] = true
	return {
		"pressed": pressed,
		"released": released,
	}


func consume_edges_once(input_frame: Dictionary, consume_edges: bool) -> Dictionary:
	return {
		"active_frame": input_frame.duplicate(true),
		"frame_active": true,
		"edges_enabled": consume_edges,
		"clear_pending_edges": consume_edges,
	}


func action_just_pressed(action_name: String, frame_state: Dictionary, fallback_fn: Callable) -> bool:
	if not bool(frame_state.get("frame_active", false)):
		return bool(fallback_fn.call(action_name)) if fallback_fn.is_valid() else false
	if not bool(frame_state.get("edges_enabled", false)):
		return false
	return bool(Dictionary(Dictionary(frame_state.get("active_frame", {})).get("pressed", {})).get(action_name, false))


func action_just_released(action_name: String, frame_state: Dictionary, fallback_fn: Callable) -> bool:
	if not bool(frame_state.get("frame_active", false)):
		return bool(fallback_fn.call(action_name)) if fallback_fn.is_valid() else false
	if not bool(frame_state.get("edges_enabled", false)):
		return false
	return bool(Dictionary(Dictionary(frame_state.get("active_frame", {})).get("released", {})).get(action_name, false))


func battle_control_routes(mode: String, ai_seat: int, runtime_menu_visible: bool) -> Dictionary:
	if runtime_menu_visible:
		return {"action": "menu_open"}
	if mode == "ai":
		if ai_seat == 1:
			return {"action": "players", "routes": [{"player_id": 1, "prefix": "p1"}]}
		if ai_seat == 2:
			return {"action": "players", "routes": [{"player_id": 2, "prefix": "p1"}]}
		return {"action": "spectator", "prefix": "p1"}
	if mode == "pvp":
		return {
			"action": "players",
			"routes": [
				{"player_id": 1, "prefix": "p1"},
				{"player_id": 2, "prefix": "p2"},
			],
		}
	if ai_seat == 2:
		return {"action": "players", "routes": [{"player_id": 2, "prefix": "p1"}]}
	if ai_seat == 3:
		return {"action": "spectator", "prefix": "p1"}
	return {"action": "players", "routes": [{"player_id": 1, "prefix": "p1"}]}


func direction_just_pressed(prefix: String, pressed_fn: Callable) -> bool:
	for suffix in ["left", "right", "up", "down"]:
		if _pressed(pressed_fn, "%s_%s" % [prefix, suffix]):
			return true
	return false


func movement_input_state(raw_input: Vector2, previous_input: Vector2, direction_just_pressed: bool) -> Dictionary:
	var has_move_input := raw_input.length() > 0.04
	return {
		"input_vector": raw_input,
		"has_move_input": has_move_input,
		"movement_just_pressed": has_move_input and (previous_input.length() <= 0.04 or direction_just_pressed),
	}


func spectator_input_intent(prefix: String, input_vector: Vector2, pressed_fn: Callable) -> Dictionary:
	var intent := {
		"input_vector": input_vector,
		"free_pan": input_vector.length() > 0.12,
		"cycle": 0,
		"view_mode": "",
	}
	if _pressed(pressed_fn, "%s_face_left" % prefix):
		intent["cycle"] = -1
	elif _pressed(pressed_fn, "%s_face_right" % prefix):
		intent["cycle"] = 1
	if _pressed(pressed_fn, "%s_attack_1" % prefix):
		intent["view_mode"] = "p1"
	elif _pressed(pressed_fn, "%s_attack_2" % prefix):
		intent["view_mode"] = "p2"
	elif _pressed(pressed_fn, "%s_attack_3" % prefix):
		intent["view_mode"] = "mid"
	elif _pressed(pressed_fn, "%s_attack_4" % prefix):
		intent["view_mode"] = "free"
	return intent


func _pressed(pressed_fn: Callable, action_name: String) -> bool:
	return bool(pressed_fn.call(action_name)) if pressed_fn.is_valid() else false
