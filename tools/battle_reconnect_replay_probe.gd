extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_input_service.gd"
const MainScene := preload("res://scripts/main.gd")
const BattleInputServiceScript := preload("res://scripts/services/battle_input_service.gd")
const StarSoulBPServiceScript := preload("res://scripts/services/star_soul_bp_service.gd")

const REPLAY_SEED := 20260629
const FRAME_COUNT := 180
const DISCONNECT_STEP := 90

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"RECONNECT_PAYLOAD_SCHEMA_VERSION",
		"func battle_reconnect_payload",
		"func serialize_battle_reconnect_payload",
		"func deserialize_battle_reconnect_payload",
		"func reconnect_replay_plan",
		"history_digest_mismatch",
	]:
		if not source.contains(token):
			_fail("BattleInputService missing reconnect replay token: %s" % token)
	if not failures.is_empty():
		_finish()
		return
	var service = BattleInputServiceScript.new()
	var action_names: Array = service.battle_action_names(["p1", "p2"], MainScene.ATTACK_GROUP_COUNT)
	var start_payload: Dictionary = _start_payload(service, action_names)
	var draft_payload := _star_soul_draft_payload()
	var serialized_frames := _serialized_frames(service, action_names)
	var midpoint := _run_steps(service, start_payload, draft_payload, serialized_frames.slice(0, DISCONNECT_STEP), "reconnect_source_midpoint")
	if midpoint.is_empty():
		_finish()
		return
	var checkpoint: Dictionary = service.replay_checkpoint(DISCONNECT_STEP, float(DISCONNECT_STEP) / MainScene.BATTLE_SIMULATION_FPS, midpoint)
	var reconnect_payload: Dictionary = service.battle_reconnect_payload(start_payload, draft_payload, serialized_frames.slice(0, DISCONNECT_STEP), checkpoint)
	var serialized_payload: String = service.serialize_battle_reconnect_payload(reconnect_payload)
	var decoded: Dictionary = service.deserialize_battle_reconnect_payload(serialized_payload)
	if not _expect(not decoded.is_empty() and service.serialize_battle_reconnect_payload(decoded) == serialized_payload, "Reconnect payload should survive stable JSON round trip."):
		_finish()
		return
	var plan: Dictionary = service.reconnect_replay_plan(decoded)
	if not _expect(bool(plan.get("accepted", false)) and int(plan.get("current_step", -1)) == DISCONNECT_STEP, "Valid reconnect payload should produce a replay plan: %s" % str(plan)):
		_finish()
		return
	var recovered_midpoint := _run_steps(service, Dictionary(plan.get("battle_start_payload", {})), Dictionary(plan.get("star_soul_draft_payload", {})), Array(plan.get("serialized_frames", [])), "reconnect_recovered_midpoint")
	if not _expect(recovered_midpoint == midpoint, "Reconnect replay should rebuild the confirmed midpoint.\nsource=%s\nrecovered=%s" % [str(midpoint), str(recovered_midpoint)]):
		_finish()
		return
	var baseline_terminal := _run_steps(service, start_payload, draft_payload, serialized_frames, "reconnect_baseline_terminal")
	var recovered_terminal_frames: Array = Array(plan.get("serialized_frames", [])).duplicate()
	recovered_terminal_frames.append_array(serialized_frames.slice(DISCONNECT_STEP))
	var recovered_terminal := _run_steps(service, Dictionary(plan.get("battle_start_payload", {})), Dictionary(plan.get("star_soul_draft_payload", {})), recovered_terminal_frames, "reconnect_recovered_terminal")
	if not _expect(recovered_terminal == baseline_terminal, "Reconnected replay should continue to the same terminal state.\nbaseline=%s\nrecovered=%s" % [str(baseline_terminal), str(recovered_terminal)]):
		_finish()
		return
	var tampered := decoded.duplicate(true)
	var tampered_frames: Array = Array(tampered.get("serialized_frames", [])).duplicate()
	tampered_frames[5] = service.serialize_input_frame({"strengths": {"p1_down": 1.0}}, action_names)
	tampered["serialized_frames"] = tampered_frames
	var tampered_plan: Dictionary = service.reconnect_replay_plan(tampered)
	if not _expect(not bool(tampered_plan.get("accepted", true)) and String(tampered_plan.get("reason", "")) == "history_digest_mismatch", "Tampered reconnect history should be rejected: %s" % str(tampered_plan)):
		_finish()
		return
	var stale_checkpoint: Dictionary = service.replay_checkpoint(DISCONNECT_STEP - 1, float(DISCONNECT_STEP - 1) / MainScene.BATTLE_SIMULATION_FPS, midpoint)
	var stale_payload: Dictionary = service.battle_reconnect_payload(start_payload, draft_payload, serialized_frames.slice(0, DISCONNECT_STEP), stale_checkpoint)
	var stale_plan: Dictionary = service.reconnect_replay_plan(stale_payload)
	_expect(not bool(stale_plan.get("accepted", true)) and String(stale_plan.get("reason", "")) == "checkpoint_step_mismatch", "Reconnect checkpoint must cover the complete bundled history: %s" % str(stale_plan))
	print("BATTLE_RECONNECT_REPLAY_PROBE step=%d digest=%s" % [DISCONNECT_STEP, String(decoded.get("history_digest", "")).left(12)])
	_finish()


func _start_payload(service, action_names: Array) -> Dictionary:
	return service.battle_start_payload(MainScene.MODE_PVP, 1, REPLAY_SEED, action_names, {
		"simulation_hz": int(roundf(MainScene.BATTLE_SIMULATION_FPS)),
		"remote_input_slots": [
			{"player_id": 1, "prefix": "p1", "source": "local", "slot_id": "local-p1"},
			{"player_id": 2, "prefix": "p2", "source": "remote", "slot_id": "remote-p2"},
		],
	})


func _star_soul_draft_payload() -> Dictionary:
	var service = StarSoulBPServiceScript.new()
	return service.build_spawn_queue([
		{"player": 1, "star_soul_id": "defense_tower_a"},
		{"player": 2, "star_soul_id": "punishment_tower_a"},
	], 1, 1, {
		"pool_ids": service.catalog_by_id().keys(),
		"announce_seconds": 0.25,
	})


func _serialized_frames(service, action_names: Array) -> Array:
	var frames: Array = []
	for step in range(FRAME_COUNT):
		var strengths := {}
		if step < 60:
			strengths = {"p1_right": 0.55, "p2_left": 0.5}
		elif step < 120:
			strengths = {"p1_down": 0.4, "p2_up": 0.35}
		else:
			strengths = {"p1_cool": 1.0, "p2_cool": 1.0}
		var pressed := {}
		var released := {}
		if step == 45:
			pressed["p1_portal"] = true
		if step == 46:
			released["p1_portal"] = true
		frames.append(service.serialize_input_frame({
			"pressed": pressed,
			"released": released,
			"strengths": strengths,
		}, action_names))
	return frames


func _run_steps(service, start_payload: Dictionary, draft_payload: Dictionary, serialized_frames: Array, reason: String) -> Dictionary:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._legalize_ai_player_roster(1, true)
	main._legalize_ai_player_roster(2, true)
	main.star_soul_battle_draft_payload = draft_payload.duplicate(true)
	main._begin_battle_from_start_payload(start_payload, true, reason)
	main.match_time_remaining = 10.0
	for serialized_frame in serialized_frames:
		main._tick_battle_with_input_frame(MainScene.BATTLE_SIMULATION_DELTA, service.deserialize_input_frame(String(serialized_frame)))
	if not _expect(int(main.battle_simulation_step_count) == serialized_frames.size(), "%s should replay every requested step: expected=%d actual=%d" % [reason, serialized_frames.size(), int(main.battle_simulation_step_count)]):
		_dispose_main(main)
		return {}
	var state: Dictionary = main._battle_replay_checkpoint_state()
	_dispose_main(main)
	return state


func _dispose_main(main) -> void:
	if main.get_parent() != null:
		main.get_parent().remove_child(main)
	main.queue_free()


func _finish() -> void:
	if not failures.is_empty():
		print("BATTLE_RECONNECT_REPLAY_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("BATTLE_RECONNECT_REPLAY_PROBE ok")
	quit(0)
