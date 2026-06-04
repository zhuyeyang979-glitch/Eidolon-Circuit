extends SceneTree

const STATE_PATH := "res://scripts/battle/state/battle_state.gd"
const BattleStateScript := preload("res://scripts/battle/state/battle_state.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(STATE_PATH):
		_fail("Missing BattleState script.")
		return
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(STATE_PATH))
	for token in [
		"class_name BattleState",
		"PHASE_IDLE",
		"PHASE_RUNNING",
		"PHASE_PRESERVED",
		"PHASE_CLEANUP",
		"func begin_runtime",
		"func preserve_runtime",
		"func record_runtime_snapshot",
		"func record_cleanup_intent",
		"func snapshot",
		"func reset",
	]:
		if source.find(token) < 0:
			_fail("BattleState missing token: %s" % token)
			return
	for forbidden in ["extends Node", "Input.", "FileAccess.open", "DirAccess", "JSON.parse_string", "Control.new", "Button", "active_units", "all_units", "_tick_battle", "_begin_battle"]:
		if source.find(forbidden) >= 0:
			_fail("BattleState should stay pure state-only; found forbidden token: %s" % forbidden)
			return
	var state = BattleStateScript.new()
	var begin_snapshot: Dictionary = state.begin_runtime("ai", "battle:ai", {"mode": "ai"})
	if String(begin_snapshot.get("battle_mode_key", "")) != "ai" or String(begin_snapshot.get("phase", "")) != "running" or int(begin_snapshot.get("reset_count", 0)) != 1:
		_fail("BattleState begin_runtime mismatch: %s" % str(begin_snapshot))
		return
	var runtime_snapshot: Dictionary = state.record_runtime_snapshot({"unit_count": 2, "pending_laser_shots": 1})
	if int(runtime_snapshot.get("unit_count", 0)) != 2 or int(state.last_runtime_snapshot.get("pending_laser_shots", 0)) != 1:
		_fail("BattleState runtime snapshot mismatch: %s" % str(runtime_snapshot))
		return
	var preserve_snapshot: Dictionary = state.preserve_runtime("return_battle", {"preserve_runtime": true})
	if String(preserve_snapshot.get("phase", "")) != "preserved" or int(preserve_snapshot.get("preserve_count", 0)) != 1:
		_fail("BattleState preserve_runtime mismatch: %s" % str(preserve_snapshot))
		return
	var cleanup_snapshot: Dictionary = state.record_cleanup_intent({"preserve": false, "clear_runtime": true})
	if String(cleanup_snapshot.get("phase", "")) == "cleanup":
		_fail("record_cleanup_intent should return the intent, not the state snapshot.")
		return
	var state_snapshot: Dictionary = state.snapshot()
	if String(state_snapshot.get("phase", "")) != "cleanup" or int(state_snapshot.get("cleanup_count", 0)) != 1:
		_fail("BattleState cleanup state mismatch: %s" % str(state_snapshot))
		return
	state.reset()
	if String(state.phase) != "idle" or state.reset_count != 0 or not state.last_runtime_snapshot.is_empty():
		_fail("BattleState reset mismatch: %s" % str(state.snapshot()))
		return
	print("BATTLE_STATE_CONTRACT_PROBE ok")
	quit(0)
