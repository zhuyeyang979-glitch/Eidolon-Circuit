extends RefCounted
class_name BattleInputService

const INPUT_FRAME_SCHEMA_VERSION := 2
const BATTLE_START_PAYLOAD_SCHEMA_VERSION := 1
const RECONNECT_PAYLOAD_SCHEMA_VERSION := 1


func battle_action_names(prefixes: Array, attack_group_count: int) -> Array:
	var actions: Array = ["battle_pause"]
	for raw_prefix in prefixes:
		var prefix := String(raw_prefix)
		for suffix in ["left", "right", "up", "down", "face_left", "face_right", "cool", "portal"]:
			actions.append("%s_%s" % [prefix, suffix])
		for attack_index in range(maxi(0, attack_group_count)):
			actions.append("%s_attack_%d" % [prefix, attack_index + 1])
	return actions


func tactical_input_contract() -> Dictionary:
	return {
		"high_frequency_hero": [
			"move",
			"turn",
			"boost",
			"attack",
			"manual_cooling",
		],
		"mid_frequency_tactical": [
			"cycle_portal",
			"pair_summon",
			"deploy_hero",
			"deploy_puppet",
			"deploy_barrier",
		],
		"low_frequency_preset": [
			"puppet_source_code",
			"barrier_ether_logic",
		],
		"forbidden_runtime_micro": [
			"puppet_direct_move",
			"puppet_direct_attack",
			"barrier_direct_move",
			"barrier_direct_attack",
		],
		"cognitive_load_guardrails": cognitive_load_contract(),
	}


func cognitive_load_contract() -> Dictionary:
	return {
		"primary_runtime_focus": "hero",
		"max_simultaneous_direct_control_roles": 1,
		"direct_control_roles": [
			"hero",
		],
		"tactical_commit_roles": [
			"puppet",
			"barrier",
		],
		"tactical_command_style": [
			"cycle_portal",
			"pair_summon_chord",
			"deploy_prebuilt_slot",
		],
		"conflict_resolution": [
			"hero_aim_reserves_turn_keys",
			"attack_window_blocks_pair_summon",
			"movement_remains_on_wasd_during_aim",
			"puppet_barrier_runtime_logic_is_preset",
		],
		"forbidden_runtime_micro": [
			"puppet_direct_move",
			"puppet_direct_attack",
			"puppet_direct_aim",
			"barrier_direct_move",
			"barrier_direct_attack",
			"barrier_direct_aim",
			"role_camera_micro_cycle",
		],
		"new_feature_gate": [
			"no_new_continuous_puppet_axis",
			"no_new_continuous_barrier_axis",
			"prefer_authoring_or_deploy_commit",
			"prefer_buffered_or_delayed_tactical_confirmation",
		],
	}


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


func capture_input_frame(action_names: Array, pending_pressed: Dictionary, pending_released: Dictionary, just_pressed_fn: Callable, just_released_fn: Callable, strength_fn: Callable) -> Dictionary:
	var frame := capture_edge_frame(action_names, pending_pressed, pending_released, just_pressed_fn, just_released_fn)
	var strengths := {}
	for raw_action in action_names:
		var action_name := String(raw_action)
		var action_strength := clampf(float(strength_fn.call(action_name)), 0.0, 1.0) if strength_fn.is_valid() else 0.0
		if action_strength > 0.0001:
			strengths[action_name] = action_strength
	frame["strengths"] = strengths
	return frame


func consume_edges_once(input_frame: Dictionary, consume_edges: bool) -> Dictionary:
	return {
		"active_frame": input_frame.duplicate(true),
		"frame_active": true,
		"edges_enabled": consume_edges,
		"clear_pending_edges": consume_edges,
	}


func canonical_input_frame(input_frame: Dictionary, action_names: Array = []) -> Dictionary:
	var allowlist := _action_allowlist(action_names)
	return {
		"schema_version": INPUT_FRAME_SCHEMA_VERSION,
		"pressed": _sorted_edge_action_names(input_frame.get("pressed", {}), allowlist),
		"released": _sorted_edge_action_names(input_frame.get("released", {}), allowlist),
		"strengths": _sorted_action_strengths(input_frame.get("strengths", {}), allowlist),
	}


func input_frame_from_canonical(canonical_frame: Dictionary) -> Dictionary:
	return {
		"pressed": _edge_dict_from_tokens(canonical_frame.get("pressed", [])),
		"released": _edge_dict_from_tokens(canonical_frame.get("released", [])),
		"strengths": _strength_dict_from_tokens(canonical_frame.get("strengths", [])),
	}


func serialize_input_frame(input_frame: Dictionary, action_names: Array = []) -> String:
	return JSON.stringify(canonical_input_frame(input_frame, action_names))


func deserialize_input_frame(serialized_frame: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(serialized_frame) != OK:
		return {"pressed": {}, "released": {}}
	var parsed = json.get_data()
	if not (parsed is Dictionary):
		return {"pressed": {}, "released": {}}
	return input_frame_from_canonical(Dictionary(parsed))


func replay_input_frame_payload(mode: String, ai_seat: int, runtime_menu_visible: bool, input_frame: Dictionary, action_names: Array = []) -> Dictionary:
	var normalized_mode := mode.strip_edges()
	var normalized_seat := clampi(ai_seat, 1, 3)
	return {
		"schema_version": INPUT_FRAME_SCHEMA_VERSION,
		"mode": normalized_mode,
		"ai_seat": normalized_seat,
		"runtime_menu_visible": runtime_menu_visible,
		"control_route": _canonical_control_route(battle_control_routes(normalized_mode, normalized_seat, runtime_menu_visible)),
		"input_frame": canonical_input_frame(input_frame, action_names),
	}


func serialize_replay_input_frame_payload(payload: Dictionary) -> String:
	return JSON.stringify(_canonical_replay_input_frame_payload(payload))


func deserialize_replay_input_frame_payload(serialized_payload: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(serialized_payload) != OK:
		return {}
	var parsed = json.get_data()
	if not (parsed is Dictionary):
		return {}
	return _canonical_replay_input_frame_payload(Dictionary(parsed))


func battle_start_payload(mode: String, ai_seat: int, replay_seed: int, action_names: Array = [], options: Dictionary = {}) -> Dictionary:
	var normalized_mode := mode.strip_edges()
	var normalized_seat := clampi(ai_seat, 1, 3)
	var runtime_menu_visible := bool(options.get("runtime_menu_visible", false))
	return {
		"schema_version": BATTLE_START_PAYLOAD_SCHEMA_VERSION,
		"input_frame_schema_version": INPUT_FRAME_SCHEMA_VERSION,
		"mode": normalized_mode,
		"ai_seat": normalized_seat,
		"replay_seed": replay_seed,
		"simulation_hz": maxi(1, int(options.get("simulation_hz", 120))),
		"runtime_menu_visible": runtime_menu_visible,
		"action_names": _sorted_action_names(action_names),
		"control_route": _canonical_control_route(battle_control_routes(normalized_mode, normalized_seat, runtime_menu_visible)),
		"remote_input_slots": _canonical_remote_input_slots(options.get("remote_input_slots", [])),
	}


func serialize_battle_start_payload(payload: Dictionary) -> String:
	return JSON.stringify(_canonical_battle_start_payload(payload))


func deserialize_battle_start_payload(serialized_payload: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(serialized_payload) != OK:
		return {}
	var parsed = json.get_data()
	if not (parsed is Dictionary):
		return {}
	return _canonical_battle_start_payload(Dictionary(parsed))


func replay_checkpoint(step: int, simulation_time: float, state: Dictionary) -> Dictionary:
	return {
		"step": maxi(0, step),
		"simulation_time": snappedf(maxf(0.0, simulation_time), 0.000001),
		"digest": replay_checkpoint_digest(state),
	}


func replay_checkpoint_digest(state: Dictionary) -> String:
	return JSON.stringify(_canonical_replay_checkpoint_value(state)).sha256_text()


func first_replay_desync(expected_checkpoints: Array, actual_checkpoints: Array) -> Dictionary:
	var shared_count := mini(expected_checkpoints.size(), actual_checkpoints.size())
	for index in range(shared_count):
		var expected := Dictionary(expected_checkpoints[index]) if expected_checkpoints[index] is Dictionary else {}
		var actual := Dictionary(actual_checkpoints[index]) if actual_checkpoints[index] is Dictionary else {}
		var expected_step := int(expected.get("step", -1))
		var actual_step := int(actual.get("step", -1))
		var expected_time := float(expected.get("simulation_time", -1.0))
		var actual_time := float(actual.get("simulation_time", -1.0))
		var expected_digest := String(expected.get("digest", ""))
		var actual_digest := String(actual.get("digest", ""))
		if expected_step != actual_step or expected_time != actual_time or expected_digest != actual_digest:
			return {
				"matched": false,
				"reason": "checkpoint_mismatch",
				"index": index,
				"expected_step": expected_step,
				"actual_step": actual_step,
				"expected_time": expected_time,
				"actual_time": actual_time,
				"expected_digest": expected_digest,
				"actual_digest": actual_digest,
			}
	if expected_checkpoints.size() != actual_checkpoints.size():
		var expected := Dictionary(expected_checkpoints[shared_count]) if shared_count < expected_checkpoints.size() and expected_checkpoints[shared_count] is Dictionary else {}
		var actual := Dictionary(actual_checkpoints[shared_count]) if shared_count < actual_checkpoints.size() and actual_checkpoints[shared_count] is Dictionary else {}
		return {
			"matched": false,
			"reason": "checkpoint_count_mismatch",
			"index": shared_count,
			"expected_count": expected_checkpoints.size(),
			"actual_count": actual_checkpoints.size(),
			"expected_step": int(expected.get("step", -1)),
			"actual_step": int(actual.get("step", -1)),
			"expected_time": float(expected.get("simulation_time", -1.0)),
			"actual_time": float(actual.get("simulation_time", -1.0)),
			"expected_digest": String(expected.get("digest", "")),
			"actual_digest": String(actual.get("digest", "")),
		}
	return {
		"matched": true,
		"reason": "match",
		"checkpoint_count": shared_count,
	}


func rollback_replay_plan(start_payload: Dictionary, serialized_frames: Array, corrections: Array, current_step: int, max_rollback_steps: int = 240) -> Dictionary:
	var canonical_start := _canonical_battle_start_payload(start_payload)
	if String(canonical_start.get("mode", "")) == "":
		return _replay_recovery_rejection("invalid_start_payload")
	if current_step < 0 or current_step > serialized_frames.size():
		return _replay_recovery_rejection("invalid_current_step")
	if corrections.is_empty():
		return _replay_recovery_rejection("no_corrections")
	var action_names: Array = Array(canonical_start.get("action_names", []))
	var canonical_frames: Array = []
	for frame_index in range(current_step):
		var serialized_frame := _canonical_serialized_input_frame(serialized_frames[frame_index], action_names)
		if serialized_frame == "":
			return _replay_recovery_rejection("invalid_history_frame", {"step": frame_index})
		canonical_frames.append(serialized_frame)
	var correction_by_step := {}
	var rollback_step := current_step
	var rollback_window := maxi(0, max_rollback_steps)
	for raw_correction in corrections:
		if not (raw_correction is Dictionary):
			return _replay_recovery_rejection("invalid_correction")
		var correction: Dictionary = Dictionary(raw_correction)
		var correction_step := int(correction.get("step", -1))
		if correction_step < 0 or correction_step >= current_step:
			return _replay_recovery_rejection("correction_out_of_range", {"step": correction_step})
		if current_step - correction_step > rollback_window:
			return _replay_recovery_rejection("correction_outside_window", {
				"step": correction_step,
				"current_step": current_step,
				"max_rollback_steps": rollback_window,
			})
		if correction_by_step.has(correction_step):
			return _replay_recovery_rejection("duplicate_correction_step", {"step": correction_step})
		var frame_value = correction.get("serialized_frame", correction.get("input_frame", null))
		var serialized_correction := _canonical_serialized_input_frame(frame_value, action_names)
		if serialized_correction == "":
			return _replay_recovery_rejection("invalid_correction_frame", {"step": correction_step})
		correction_by_step[correction_step] = serialized_correction
		rollback_step = mini(rollback_step, correction_step)
	var corrected_steps: Array = correction_by_step.keys()
	corrected_steps.sort()
	for raw_step in corrected_steps:
		var step := int(raw_step)
		canonical_frames[step] = String(correction_by_step[step])
	return {
		"accepted": true,
		"reason": "rollback_replay",
		"rollback_step": rollback_step,
		"replay_from_step": 0,
		"current_step": current_step,
		"resimulate_steps": current_step,
		"max_rollback_steps": rollback_window,
		"corrected_steps": corrected_steps,
		"battle_start_payload": canonical_start,
		"serialized_frames": canonical_frames,
	}


func battle_reconnect_payload(start_payload: Dictionary, star_soul_draft_payload: Dictionary, serialized_frames: Array, confirmed_checkpoint: Dictionary) -> Dictionary:
	var core := _battle_reconnect_payload_core({
		"schema_version": RECONNECT_PAYLOAD_SCHEMA_VERSION,
		"battle_start_payload": start_payload,
		"star_soul_draft_payload": star_soul_draft_payload,
		"current_step": serialized_frames.size(),
		"serialized_frames": serialized_frames,
		"confirmed_checkpoint": confirmed_checkpoint,
	})
	core["history_digest"] = _battle_reconnect_history_digest(core)
	return core


func serialize_battle_reconnect_payload(payload: Dictionary) -> String:
	return JSON.stringify(_canonical_battle_reconnect_payload(payload))


func deserialize_battle_reconnect_payload(serialized_payload: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(serialized_payload) != OK:
		return {}
	var parsed = json.get_data()
	if not (parsed is Dictionary):
		return {}
	return _canonical_battle_reconnect_payload(Dictionary(parsed))


func reconnect_replay_plan(payload: Dictionary) -> Dictionary:
	var canonical := _canonical_battle_reconnect_payload(payload)
	if int(canonical.get("schema_version", 0)) != RECONNECT_PAYLOAD_SCHEMA_VERSION:
		return _replay_recovery_rejection("unsupported_reconnect_schema")
	var start_payload: Dictionary = Dictionary(canonical.get("battle_start_payload", {}))
	if String(start_payload.get("mode", "")) == "":
		return _replay_recovery_rejection("invalid_start_payload")
	var draft_payload: Dictionary = Dictionary(canonical.get("star_soul_draft_payload", {}))
	if not bool(draft_payload.get("valid", false)):
		return _replay_recovery_rejection("invalid_star_soul_draft")
	var current_step := int(canonical.get("current_step", -1))
	var serialized_frames: Array = Array(canonical.get("serialized_frames", []))
	if current_step < 0 or serialized_frames.size() != current_step:
		return _replay_recovery_rejection("history_length_mismatch", {
			"current_step": current_step,
			"frame_count": serialized_frames.size(),
		})
	for frame_index in range(serialized_frames.size()):
		if String(serialized_frames[frame_index]) == "":
			return _replay_recovery_rejection("invalid_history_frame", {"step": frame_index})
	var checkpoint: Dictionary = Dictionary(canonical.get("confirmed_checkpoint", {}))
	if int(checkpoint.get("step", -1)) != current_step:
		return _replay_recovery_rejection("checkpoint_step_mismatch", {
			"current_step": current_step,
			"checkpoint_step": int(checkpoint.get("step", -1)),
		})
	var simulation_hz := maxi(1, int(start_payload.get("simulation_hz", 120)))
	var expected_checkpoint_time := snappedf(float(current_step) / float(simulation_hz), 0.000001)
	var actual_checkpoint_time := float(checkpoint.get("simulation_time", -1.0))
	if actual_checkpoint_time != expected_checkpoint_time:
		return _replay_recovery_rejection("checkpoint_time_mismatch", {
			"expected_time": expected_checkpoint_time,
			"actual_time": actual_checkpoint_time,
		})
	var checkpoint_digest := String(checkpoint.get("digest", ""))
	if checkpoint_digest.length() != 64 or not checkpoint_digest.is_valid_hex_number():
		return _replay_recovery_rejection("invalid_checkpoint_digest")
	var expected_digest := _battle_reconnect_history_digest(_battle_reconnect_payload_core(canonical))
	var actual_digest := String(canonical.get("history_digest", ""))
	if actual_digest != expected_digest:
		return _replay_recovery_rejection("history_digest_mismatch", {
			"expected_digest": expected_digest,
			"actual_digest": actual_digest,
		})
	return {
		"accepted": true,
		"reason": "reconnect_replay",
		"current_step": current_step,
		"replay_from_step": 0,
		"battle_start_payload": start_payload,
		"star_soul_draft_payload": draft_payload,
		"serialized_frames": serialized_frames,
		"confirmed_checkpoint": checkpoint,
		"history_digest": actual_digest,
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


func action_pressed(action_name: String, frame_state: Dictionary, fallback_fn: Callable) -> bool:
	if not bool(frame_state.get("frame_active", false)):
		return bool(fallback_fn.call(action_name)) if fallback_fn.is_valid() else false
	var active_frame := Dictionary(frame_state.get("active_frame", {}))
	var strengths := Dictionary(active_frame.get("strengths", {}))
	if strengths.has(action_name):
		return float(strengths.get(action_name, 0.0)) > 0.0001
	if bool(frame_state.get("edges_enabled", false)):
		return bool(Dictionary(active_frame.get("pressed", {})).get(action_name, false))
	return false


func action_strength(action_name: String, frame_state: Dictionary, fallback_fn: Callable) -> float:
	if not bool(frame_state.get("frame_active", false)):
		return clampf(float(fallback_fn.call(action_name)), 0.0, 1.0) if fallback_fn.is_valid() else 0.0
	var active_frame := Dictionary(frame_state.get("active_frame", {}))
	var strengths := Dictionary(active_frame.get("strengths", {}))
	if strengths.has(action_name):
		return clampf(float(strengths.get(action_name, 0.0)), 0.0, 1.0)
	if bool(frame_state.get("edges_enabled", false)) and bool(Dictionary(active_frame.get("pressed", {})).get(action_name, false)):
		return 1.0
	return 0.0


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


func input_vector_from_strengths(right_strength: float, left_strength: float, down_strength: float, up_strength: float, deadzone: float = 0.08) -> Vector2:
	var input_vector := Vector2(right_strength - left_strength, down_strength - up_strength)
	if input_vector.length() <= maxf(0.0, deadzone):
		return Vector2.ZERO
	return input_vector.normalized() if input_vector.length() > 1.0 else input_vector


func gun_turn_input_vector_from_strengths(face_right_strength: float, face_left_strength: float, deadzone: float = 0.08) -> Vector2:
	var x := face_right_strength - face_left_strength
	if absf(x) <= maxf(0.0, deadzone):
		return Vector2.ZERO
	return Vector2(clampf(x, -1.0, 1.0), 0.0)


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


func _canonical_replay_input_frame_payload(payload: Dictionary) -> Dictionary:
	var mode := String(payload.get("mode", "")).strip_edges()
	var ai_seat := clampi(int(payload.get("ai_seat", 1)), 1, 3)
	var runtime_menu_visible := bool(payload.get("runtime_menu_visible", false))
	var input_frame := Dictionary(payload.get("input_frame", {})) if payload.get("input_frame", {}) is Dictionary else {}
	return {
		"schema_version": INPUT_FRAME_SCHEMA_VERSION,
		"mode": mode,
		"ai_seat": ai_seat,
		"runtime_menu_visible": runtime_menu_visible,
		"control_route": _canonical_control_route(payload.get("control_route", battle_control_routes(mode, ai_seat, runtime_menu_visible))),
		"input_frame": canonical_input_frame(input_frame),
	}


func _canonical_battle_start_payload(payload: Dictionary) -> Dictionary:
	var mode := String(payload.get("mode", "")).strip_edges()
	var ai_seat := clampi(int(payload.get("ai_seat", 1)), 1, 3)
	var runtime_menu_visible := bool(payload.get("runtime_menu_visible", false))
	return {
		"schema_version": BATTLE_START_PAYLOAD_SCHEMA_VERSION,
		"input_frame_schema_version": INPUT_FRAME_SCHEMA_VERSION,
		"mode": mode,
		"ai_seat": ai_seat,
		"replay_seed": int(payload.get("replay_seed", 0)),
		"simulation_hz": maxi(1, int(payload.get("simulation_hz", 120))),
		"runtime_menu_visible": runtime_menu_visible,
		"action_names": _sorted_action_names(payload.get("action_names", [])),
		"control_route": _canonical_control_route(payload.get("control_route", battle_control_routes(mode, ai_seat, runtime_menu_visible))),
		"remote_input_slots": _canonical_remote_input_slots(payload.get("remote_input_slots", [])),
	}


func _canonical_battle_reconnect_payload(payload: Dictionary) -> Dictionary:
	var canonical := _battle_reconnect_payload_core(payload)
	canonical["history_digest"] = String(payload.get("history_digest", "")).to_lower()
	return canonical


func _battle_reconnect_payload_core(payload: Dictionary) -> Dictionary:
	var start_payload := _canonical_battle_start_payload(Dictionary(payload.get("battle_start_payload", {})) if payload.get("battle_start_payload", {}) is Dictionary else {})
	var action_names: Array = Array(start_payload.get("action_names", []))
	var serialized_frames: Array = []
	for raw_frame in Array(payload.get("serialized_frames", [])):
		serialized_frames.append(_canonical_serialized_input_frame(raw_frame, action_names))
	return {
		"schema_version": int(payload.get("schema_version", 0)),
		"battle_start_payload": start_payload,
		"star_soul_draft_payload": _canonical_star_soul_draft_payload(payload.get("star_soul_draft_payload", {})),
		"current_step": int(payload.get("current_step", serialized_frames.size())),
		"serialized_frames": serialized_frames,
		"confirmed_checkpoint": _canonical_replay_checkpoint(payload.get("confirmed_checkpoint", {})),
	}


func _battle_reconnect_history_digest(core_payload: Dictionary) -> String:
	return JSON.stringify(_battle_reconnect_payload_core(core_payload)).sha256_text()


func _canonical_star_soul_draft_payload(draft_value) -> Dictionary:
	var draft := Dictionary(draft_value) if draft_value is Dictionary else {}
	var errors: Array = []
	for raw_error in Array(draft.get("errors", [])):
		errors.append(String(raw_error))
	errors.sort()
	var queue: Array = []
	for raw_entry in Array(draft.get("queue", [])):
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = Dictionary(raw_entry)
		queue.append({
			"sequence_index": int(entry.get("sequence_index", queue.size())),
			"owner": int(entry.get("owner", 0)),
			"opponent": int(entry.get("opponent", 0)),
			"star_soul_id": String(entry.get("star_soul_id", "")),
			"announce_seconds": snappedf(maxf(0.0, float(entry.get("announce_seconds", 0.0))), 0.000001),
		})
	return {
		"valid": bool(draft.get("valid", false)),
		"errors": errors,
		"queue": queue,
	}


func _canonical_replay_checkpoint(checkpoint_value) -> Dictionary:
	var checkpoint := Dictionary(checkpoint_value) if checkpoint_value is Dictionary else {}
	return {
		"step": int(checkpoint.get("step", -1)),
		"simulation_time": snappedf(float(checkpoint.get("simulation_time", -1.0)), 0.000001),
		"digest": String(checkpoint.get("digest", "")).to_lower(),
	}


func _canonical_serialized_input_frame(frame_value, action_names: Array) -> String:
	var runtime_frame: Dictionary = {}
	if frame_value is String:
		var json := JSON.new()
		if json.parse(String(frame_value)) != OK:
			return ""
		var parsed = json.get_data()
		if not (parsed is Dictionary):
			return ""
		var canonical_frame: Dictionary = Dictionary(parsed)
		if not _serialized_canonical_input_frame_valid(canonical_frame):
			return ""
		runtime_frame = input_frame_from_canonical(canonical_frame)
	elif frame_value is Dictionary:
		var frame: Dictionary = Dictionary(frame_value)
		var looks_canonical := frame.has("schema_version") or frame.get("pressed", null) is Array or frame.get("released", null) is Array or frame.get("strengths", null) is Array
		if looks_canonical:
			if not _serialized_canonical_input_frame_valid(frame):
				return ""
			runtime_frame = input_frame_from_canonical(frame)
		else:
			for key in ["pressed", "released", "strengths"]:
				if frame.has(key) and not (frame.get(key) is Dictionary):
					return ""
			runtime_frame = frame
	else:
		return ""
	return serialize_input_frame(runtime_frame, action_names)


func _serialized_canonical_input_frame_valid(frame: Dictionary) -> bool:
	return (
		int(frame.get("schema_version", 0)) == INPUT_FRAME_SCHEMA_VERSION
		and frame.get("pressed", null) is Array
		and frame.get("released", null) is Array
		and frame.get("strengths", null) is Array
	)


func _replay_recovery_rejection(reason: String, details: Dictionary = {}) -> Dictionary:
	var result := {
		"accepted": false,
		"reason": reason,
	}
	for key in details.keys():
		result[key] = details[key]
	return result


func _canonical_control_route(route_value) -> Dictionary:
	var route := Dictionary(route_value) if route_value is Dictionary else {}
	var action := String(route.get("action", "none"))
	var result := {"action": action}
	if route.has("prefix"):
		result["prefix"] = String(route.get("prefix", ""))
	var routes: Array = []
	for raw_route in Array(route.get("routes", [])):
		if not (raw_route is Dictionary):
			continue
		var player_route: Dictionary = Dictionary(raw_route)
		routes.append({
			"player_id": int(player_route.get("player_id", 0)),
			"prefix": String(player_route.get("prefix", "")),
		})
	if not routes.is_empty():
		result["routes"] = routes
	return result


func _canonical_remote_input_slots(slots_value) -> Array:
	var slots: Array = []
	for raw_slot in Array(slots_value):
		if not (raw_slot is Dictionary):
			continue
		var slot: Dictionary = Dictionary(raw_slot)
		var player_id := clampi(int(slot.get("player_id", 0)), 0, 2)
		var prefix := String(slot.get("prefix", ""))
		var source := String(slot.get("source", "local"))
		var slot_id := String(slot.get("slot_id", "p%d:%s:%s" % [player_id, prefix, source]))
		slots.append({
			"player_id": player_id,
			"prefix": prefix,
			"source": source,
			"slot_id": slot_id,
		})
	slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("player_id", 0)) != int(b.get("player_id", 0)):
			return int(a.get("player_id", 0)) < int(b.get("player_id", 0))
		if String(a.get("prefix", "")) != String(b.get("prefix", "")):
			return String(a.get("prefix", "")) < String(b.get("prefix", ""))
		return String(a.get("slot_id", "")) < String(b.get("slot_id", ""))
	)
	return slots


func _sorted_action_names(action_names_value) -> Array:
	var names: Array = []
	for raw_action_name in Array(action_names_value):
		var action_name := String(raw_action_name)
		if action_name != "":
			names.append(action_name)
	names.sort()
	var result: Array = []
	var seen := {}
	for action_name in names:
		if bool(seen.get(action_name, false)):
			continue
		seen[action_name] = true
		result.append(action_name)
	return result


func _action_allowlist(action_names: Array) -> Dictionary:
	var allowlist := {}
	for raw_action_name in action_names:
		var action_name := String(raw_action_name)
		if action_name != "":
			allowlist[action_name] = true
	return allowlist


func _sorted_edge_action_names(edge_source, allowlist: Dictionary) -> Array:
	var actions: Array = []
	if edge_source is Dictionary:
		for raw_action_name in Dictionary(edge_source).keys():
			var action_name := String(raw_action_name)
			if action_name == "":
				continue
			if not bool(Dictionary(edge_source).get(raw_action_name, false)):
				continue
			if not allowlist.is_empty() and not bool(allowlist.get(action_name, false)):
				continue
			actions.append(action_name)
	elif edge_source is Array:
		for raw_action_name in Array(edge_source):
			var action_name := String(raw_action_name)
			if action_name == "":
				continue
			if not allowlist.is_empty() and not bool(allowlist.get(action_name, false)):
				continue
			actions.append(action_name)
	actions.sort()
	var unique_actions: Array = []
	var seen := {}
	for action_name in actions:
		if bool(seen.get(action_name, false)):
			continue
		seen[action_name] = true
		unique_actions.append(action_name)
	return unique_actions


func _sorted_action_strengths(strength_source, allowlist: Dictionary) -> Array:
	var strengths := {}
	if strength_source is Dictionary:
		for raw_action_name in Dictionary(strength_source).keys():
			var action_name := String(raw_action_name)
			if action_name == "" or (not allowlist.is_empty() and not bool(allowlist.get(action_name, false))):
				continue
			var value := clampf(float(Dictionary(strength_source).get(raw_action_name, 0.0)), 0.0, 1.0)
			if value > 0.0001:
				strengths[action_name] = value
	elif strength_source is Array:
		for raw_entry in Array(strength_source):
			if not (raw_entry is Dictionary):
				continue
			var entry: Dictionary = Dictionary(raw_entry)
			var action_name := String(entry.get("action", ""))
			if action_name == "" or (not allowlist.is_empty() and not bool(allowlist.get(action_name, false))):
				continue
			var value := clampf(float(entry.get("strength", entry.get("value", 0.0))), 0.0, 1.0)
			if value > 0.0001:
				strengths[action_name] = value
	var action_names: Array = strengths.keys()
	action_names.sort()
	var result: Array = []
	for action_name in action_names:
		result.append({"action": action_name, "strength": float(strengths[action_name])})
	return result


func _edge_dict_from_tokens(edge_source) -> Dictionary:
	var result := {}
	for action_name in _sorted_edge_action_names(edge_source, {}):
		result[String(action_name)] = true
	return result


func _strength_dict_from_tokens(strength_source) -> Dictionary:
	var result := {}
	for raw_entry in Array(strength_source):
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = Dictionary(raw_entry)
		var action_name := String(entry.get("action", ""))
		var value := clampf(float(entry.get("strength", entry.get("value", 0.0))), 0.0, 1.0)
		if action_name != "" and value > 0.0001:
			result[action_name] = value
	return result


func _canonical_replay_checkpoint_value(value):
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return value
		TYPE_FLOAT:
			return snappedf(float(value), 0.000001)
		TYPE_STRING_NAME:
			return String(value)
		TYPE_VECTOR2:
			var vector: Vector2 = value
			return {"type": "vector2", "x": snappedf(vector.x, 0.000001), "y": snappedf(vector.y, 0.000001)}
		TYPE_VECTOR2I:
			var vector: Vector2i = value
			return {"type": "vector2i", "x": vector.x, "y": vector.y}
		TYPE_COLOR:
			var color: Color = value
			return {
				"type": "color",
				"r": snappedf(color.r, 0.000001),
				"g": snappedf(color.g, 0.000001),
				"b": snappedf(color.b, 0.000001),
				"a": snappedf(color.a, 0.000001),
			}
		TYPE_ARRAY:
			var items: Array = []
			for item in Array(value):
				items.append(_canonical_replay_checkpoint_value(item))
			return {"type": "array", "items": items}
		TYPE_DICTIONARY:
			var rows: Array = []
			for raw_key in Dictionary(value).keys():
				rows.append({
					"sort_key": "%03d:%s" % [typeof(raw_key), str(raw_key)],
					"key_type": typeof(raw_key),
					"key": str(raw_key),
					"value": _canonical_replay_checkpoint_value(Dictionary(value).get(raw_key)),
				})
			rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return String(a.get("sort_key", "")) < String(b.get("sort_key", ""))
			)
			var entries: Array = []
			for row in rows:
				entries.append({
					"key_type": int(Dictionary(row).get("key_type", TYPE_NIL)),
					"key": String(Dictionary(row).get("key", "")),
					"value": Dictionary(row).get("value"),
				})
			return {"type": "dictionary", "entries": entries}
	return {"type": "unsupported", "variant_type": typeof(value)}


func _pressed(pressed_fn: Callable, action_name: String) -> bool:
	return bool(pressed_fn.call(action_name)) if pressed_fn.is_valid() else false
