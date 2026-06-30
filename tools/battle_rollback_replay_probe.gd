extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_input_service.gd"
const MainScene := preload("res://scripts/main.gd")
const BattleInputServiceScript := preload("res://scripts/services/battle_input_service.gd")
const StarSoulBPServiceScript := preload("res://scripts/services/star_soul_bp_service.gd")

const REPLAY_SEED := 20260629
const FRAME_COUNT := 180
const CORRECTION_STEP := 75

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
		"func rollback_replay_plan",
		"rollback_step",
		"replay_from_step",
		"correction_outside_window",
	]:
		if not source.contains(token):
			_fail("BattleInputService missing rollback replay token: %s" % token)
	if not failures.is_empty():
		_finish()
		return
	var service = BattleInputServiceScript.new()
	var action_names: Array = service.battle_action_names(["p1", "p2"], MainScene.ATTACK_GROUP_COUNT)
	var start_payload: Dictionary = _start_payload(service, action_names)
	var draft_payload := _star_soul_draft_payload()
	var baseline_frames := _serialized_frames(service, action_names, true)
	var predicted_frames := _serialized_frames(service, action_names, false)
	var baseline_state := _run_steps(service, start_payload, draft_payload, baseline_frames, "rollback_baseline")
	var predicted_state := _run_steps(service, start_payload, draft_payload, predicted_frames, "rollback_predicted")
	if baseline_state.is_empty() or predicted_state.is_empty():
		_finish()
		return
	if not _expect(baseline_state != predicted_state, "Missing remote portal edge should produce a divergent predicted state."):
		_finish()
		return
	var plan: Dictionary = service.rollback_replay_plan(start_payload, predicted_frames, [
		{"step": CORRECTION_STEP, "serialized_frame": baseline_frames[CORRECTION_STEP]},
		{"step": CORRECTION_STEP + 1, "serialized_frame": baseline_frames[CORRECTION_STEP + 1]},
	], FRAME_COUNT, 120)
	if not _expect(bool(plan.get("accepted", false)), "In-window rollback correction should be accepted: %s" % str(plan)):
		_finish()
		return
	if not _expect(int(plan.get("rollback_step", -1)) == CORRECTION_STEP and int(plan.get("replay_from_step", -1)) == 0, "Input-history rollback should report correction step %d and replay from deterministic battle start: %s" % [CORRECTION_STEP, str(plan)]):
		_finish()
		return
	var recovered_frames: Array = Array(plan.get("serialized_frames", []))
	var recovered_state := _run_steps(service, start_payload, draft_payload, recovered_frames, "rollback_recovered")
	if not _expect(recovered_state == baseline_state, "Corrected rollback replay should converge to baseline.\nbaseline=%s\nrecovered=%s" % [str(baseline_state), str(recovered_state)]):
		_finish()
		return
	var stale_plan: Dictionary = service.rollback_replay_plan(start_payload, predicted_frames, [
		{"step": 10, "serialized_frame": baseline_frames[10]},
	], FRAME_COUNT, 60)
	_expect(not bool(stale_plan.get("accepted", true)) and String(stale_plan.get("reason", "")) == "correction_outside_window", "Out-of-window rollback correction should be rejected: %s" % str(stale_plan))
	print("BATTLE_ROLLBACK_REPLAY_PROBE rollback_step=%d frames=%d" % [int(plan.get("rollback_step", -1)), recovered_frames.size()])
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


func _serialized_frames(service, action_names: Array, include_remote_portal: bool) -> Array:
	var frames: Array = []
	for step in range(FRAME_COUNT):
		var strengths := {
			"p1_right": 0.45 if step < 90 else 0.0,
			"p2_left": 0.4 if step < 90 else 0.0,
		}
		var pressed := {}
		var released := {}
		if include_remote_portal and step == CORRECTION_STEP:
			pressed["p2_portal"] = true
		if include_remote_portal and step == CORRECTION_STEP + 1:
			released["p2_portal"] = true
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
		print("BATTLE_ROLLBACK_REPLAY_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("BATTLE_ROLLBACK_REPLAY_PROBE ok")
	quit(0)
