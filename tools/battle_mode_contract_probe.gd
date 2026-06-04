extends SceneTree

const MODE_PATH := "res://scripts/modes/battle_mode.gd"
const STATE_PATH := "res://scripts/battle/state/battle_state.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleModeScript := preload("res://scripts/modes/battle_mode.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(MODE_PATH):
		_fail("Missing BattleMode script.")
		return
	if not FileAccess.file_exists(STATE_PATH):
		_fail("Missing BattleState script.")
		return
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MODE_PATH))
	for token in [
		"class_name BattleMode",
		"BattleStateScript",
		"MODE_KEY := \"battle\"",
		"TRAINING_MODE_KEY := \"training\"",
		"func bind",
		"func show_intent",
		"func commit_show",
		"func enter_intent",
		"func commit_enter",
		"func runtime_snapshot",
		"func cleanup_intent",
		"func commit_cleanup",
		"func exit_intent",
		"func commit_exit",
		"func state_snapshot",
	]:
		if source.find(token) < 0:
			_fail("BattleMode missing token: %s" % token)
			return
	for forbidden in ["Input.", "FileAccess.open", "DirAccess", "JSON.parse_string", "Control.new", "Button", "active_units", "all_units", "_tick_battle", "_begin_battle", "_summon_role", "_update_units", "_resolve_damage"]:
		if source.find(forbidden) >= 0:
			_fail("BattleMode should stay runtime-boundary only; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattleMode = preload(\"res://scripts/modes/battle_mode.gd\")",
		"var battle_mode_owner: BattleMode",
		"battle_mode_owner = BattleMode.new()",
		"battle_mode_owner.bind(self, battle_controller, battle_runtime_lifecycle_service)",
		"func _commit_battle_mode_enter",
		"func _commit_battle_mode_exit",
		"battle_mode_owner.enter_intent",
		"battle_mode_owner.commit_enter",
		"battle_mode_owner.exit_intent",
		"battle_mode_owner.commit_exit",
		"func _battle_mode_show_intent",
		"battle_mode_owner.show_intent",
		"func _commit_battle_mode_show_intent",
		"battle_mode_owner.commit_show",
		"func _battle_mode_runtime_snapshot",
		"battle_mode_owner.runtime_snapshot",
		"func _battle_mode_cleanup_intent",
		"battle_mode_owner.cleanup_intent",
		"func _commit_battle_cleanup_intent",
		"battle_mode_owner.commit_cleanup",
		"_commit_battle_mode_enter(nav_reason, payload)",
		"_commit_battle_mode_exit(reason, payload)",
		"var show_intent := _battle_mode_show_intent(mode, preloaded, loading_queued, nav_reason, false)",
		"var show_intent := _battle_mode_show_intent(battle_mode, true, false, reason, true)",
		"var cleanup_intent := _battle_mode_cleanup_intent(_battle_runtime_lifecycle_snapshot(), preserve_for_return)",
		"_commit_battle_cleanup_intent(cleanup_intent)",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd missing BattleMode wiring token: %s" % token)
			return
	var mode = BattleModeScript.new()
	if mode.mode_key() != "battle":
		_fail("BattleMode mode_key mismatch: %s" % mode.mode_key())
		return
	if mode.app_mode_key_for_battle_mode("training") != "training" or mode.app_mode_key_for_battle_mode("ai") != "battle":
		_fail("BattleMode app mode mapping mismatch.")
		return
	var show_battle: Dictionary = mode.show_intent("ai", false, false)
	if String(show_battle.get("mode_key", "")) != "battle" or String(show_battle.get("battle_mode", "")) != "ai" or not bool(show_battle.get("reset_runtime", false)):
		_fail("BattleMode show_intent mismatch: %s" % str(show_battle))
		return
	if not mode.commit_show(show_battle):
		_fail("BattleMode commit_show failed.")
		return
	if String(mode.state_snapshot().get("phase", "")) != "running":
		_fail("BattleMode state should be running after show: %s" % str(mode.state_snapshot()))
		return
	var show_training: Dictionary = mode.show_intent("training", true, false, "battle:training")
	if String(show_training.get("mode_key", "")) != "training":
		_fail("BattleMode training show should map to training app mode: %s" % str(show_training))
		return
	var show_preserve: Dictionary = mode.show_intent("ai", true, false, "return_battle", true)
	if not bool(show_preserve.get("preserve_runtime", false)) or bool(show_preserve.get("reset_runtime", true)):
		_fail("BattleMode preserve show_intent mismatch: %s" % str(show_preserve))
		return
	mode.commit_show(show_preserve)
	if String(mode.state_snapshot().get("phase", "")) != "preserved":
		_fail("BattleMode state should be preserved: %s" % str(mode.state_snapshot()))
		return
	var runtime_snapshot: Dictionary = mode.runtime_snapshot({"unit_count": 2, "pending_laser_shots": 1, "battle_effect_children": 3})
	if int(runtime_snapshot.get("battle_effect_children", 0)) != 3:
		_fail("BattleMode runtime_snapshot mismatch: %s" % str(runtime_snapshot))
		return
	var cleanup_preserve: Dictionary = mode.cleanup_intent(runtime_snapshot, true)
	if not bool(cleanup_preserve.get("preserve", false)) or bool(cleanup_preserve.get("clear_runtime", true)):
		_fail("BattleMode preserve cleanup mismatch: %s" % str(cleanup_preserve))
		return
	if not mode.commit_cleanup(cleanup_preserve):
		_fail("BattleMode preserve cleanup commit failed.")
		return
	var cleanup_clear: Dictionary = mode.cleanup_intent(runtime_snapshot, false)
	if bool(cleanup_clear.get("preserve", true)) or not bool(cleanup_clear.get("clear_units", false)) or not bool(cleanup_clear.get("clear_aim_state", false)):
		_fail("BattleMode clear cleanup mismatch: %s" % str(cleanup_clear))
		return
	if not mode.commit_cleanup(cleanup_clear):
		_fail("BattleMode clear cleanup commit failed.")
		return
	var enter_intent: Dictionary = mode.enter_intent("battle:ai", {"mode": "ai"})
	if not mode.commit_enter(enter_intent) or mode.enter_count != 1:
		_fail("BattleMode commit_enter failed.")
		return
	var exit_intent: Dictionary = mode.exit_intent("settings", {"preserve_runtime": true})
	if not mode.commit_exit(exit_intent) or mode.exit_count != 1:
		_fail("BattleMode commit_exit failed.")
		return
	print("BATTLE_MODE_CONTRACT_PROBE ok")
	quit(0)
