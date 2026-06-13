extends SceneTree

const MODE_PATH := "res://scripts/modes/training_mode.gd"
const MAIN_PATH := "res://scripts/main.gd"
const TrainingModeScript := preload("res://scripts/modes/training_mode.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(MODE_PATH):
		_fail("Missing TrainingMode script.")
		return
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MODE_PATH))
	for token in [
		"class_name TrainingMode",
		"MODE_KEY := \"training\"",
		"func bind",
		"func config_intent",
		"func commit_config",
		"func scout_show_intent",
		"func begin_from_scout_intent",
		"func enter_intent",
		"func commit_enter",
		"func exit_intent",
		"func commit_exit",
	]:
		if source.find(token) < 0:
			_fail("TrainingMode missing token: %s" % token)
			return
	for forbidden in ["Input.", "FileAccess.open", "DirAccess", "JSON.parse_string", "Control.new", "Button", "_begin_battle", "_configure_training_sides_for_seat", "_prepare_training_battle_loadouts", "active_units", "all_units"]:
		if source.find(forbidden) >= 0:
			_fail("TrainingMode should stay training-setup-boundary only; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const TrainingMode = preload(\"res://scripts/modes/training_mode.gd\")",
		"var training_mode_owner: TrainingMode",
		"training_mode_owner = TrainingMode.new()",
		"training_mode_owner.bind(self, scout_controller)",
		"func _commit_training_mode_enter",
		"func _commit_training_mode_exit",
		"training_mode_owner.enter_intent",
		"training_mode_owner.commit_enter",
		"training_mode_owner.exit_intent",
		"training_mode_owner.commit_exit",
		"func _training_config_intent",
		"training_mode_owner.config_intent",
		"func _commit_training_config_intent",
		"training_mode_owner.commit_config",
		"func _training_scout_show_intent",
		"training_mode_owner.scout_show_intent",
		"func _training_begin_from_scout_intent",
		"training_mode_owner.begin_from_scout_intent",
		"_commit_training_mode_enter(nav_reason, payload)",
		"_commit_training_mode_exit(reason, payload)",
		"var config_intent := _training_config_intent(clear_imports)",
		"var show_intent := _training_scout_show_intent(mode, preloaded, loading_queued)",
		"var training_begin_intent := _training_begin_from_scout_intent()",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd missing TrainingMode wiring token: %s" % token)
			return
	var mode = TrainingModeScript.new()
	if mode.mode_key() != "training":
		_fail("TrainingMode mode_key mismatch: %s" % mode.mode_key())
		return
	var config_intent: Dictionary = mode.config_intent(true)
	if not bool(config_intent.get("clear_imports", false)) or not bool(config_intent.get("prepare_loadouts", false)) or String(config_intent.get("handoff_mode", "")) != "training":
		_fail("TrainingMode config_intent mismatch: %s" % str(config_intent))
		return
	if not mode.commit_config(config_intent) or String(mode.last_config_context.get("reason", "")) != "training_config":
		_fail("TrainingMode commit_config failed.")
		return
	var scout_wait: Dictionary = mode.scout_show_intent(false, true)
	if bool(scout_wait.get("should_apply", true)) or not bool(scout_wait.get("loading_queued", false)) or String(Dictionary(scout_wait.get("payload", {})).get("mode", "")) != "training":
		_fail("TrainingMode queued scout_show_intent mismatch: %s" % str(scout_wait))
		return
	var scout_now: Dictionary = mode.scout_show_intent(true, false)
	if not bool(scout_now.get("should_apply", false)) or not bool(scout_now.get("reset_training_seat", false)):
		_fail("TrainingMode apply scout_show_intent mismatch: %s" % str(scout_now))
		return
	var require_seat: Dictionary = mode.begin_from_scout_intent("training", false)
	if String(require_seat.get("action", "")) != "require_training_seat" or not bool(require_seat.get("extend_timer", false)):
		_fail("TrainingMode missing-seat intent mismatch: %s" % str(require_seat))
		return
	var trimmed_require_seat: Dictionary = mode.begin_from_scout_intent("  training  ", false)
	if String(trimmed_require_seat.get("action", "")) != "require_training_seat" or String(trimmed_require_seat.get("pending_mode", "")) != "training":
		_fail("TrainingMode should normalize pending training mode before seat gate: %s" % str(trimmed_require_seat))
		return
	var begin_training: Dictionary = mode.begin_from_scout_intent("training", true)
	if String(begin_training.get("action", "")) != "configure_and_begin_training":
		_fail("TrainingMode begin intent mismatch: %s" % str(begin_training))
		return
	var ignored: Dictionary = mode.begin_from_scout_intent("ai", false)
	if bool(ignored.get("handled", true)):
		_fail("TrainingMode should ignore non-training scout begin: %s" % str(ignored))
		return
	var enter_intent: Dictionary = mode.enter_intent("scout:training", {"mode": "training"})
	if not mode.commit_enter(enter_intent) or mode.enter_count != 1:
		_fail("TrainingMode commit_enter failed.")
		return
	if mode.commit_enter({"mode_key": "battle"}):
		_fail("TrainingMode should reject wrong-mode enter commits.")
		return
	var exit_intent: Dictionary = mode.exit_intent("battle:training")
	if not mode.commit_exit(exit_intent) or mode.exit_count != 1:
		_fail("TrainingMode commit_exit failed.")
		return
	print("TRAINING_MODE_CONTRACT_PROBE ok")
	quit(0)
