extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_training_config(true)
	main._select_ai_battle_seat(1)
	var start_button := main.scout_layer.find_child("ScoutStartButton", true, false) as Button
	if start_button == null or start_button.disabled:
		_fail("Scout training start button is unavailable.")
	start_button.pressed.emit()
	if main.game_state != MainScene.STATE_BATTLE:
		_fail("Training should begin with the dedicated ball dummy instead of requiring Unit4: %s" % String(main.training_import_error_note))
	var dummy_player := 2
	var dummy = main.active_units[dummy_player]["hero"]
	if not main._is_live_unit(dummy) or not bool(dummy.stats.get("training_ball_dummy", false)):
		_fail("Training should spawn a dedicated ball dummy on the opponent side.")
	print("TRAINING_START_MISSING_DUMMY_FEEDBACK_PROBE ok ball_radius=%.2f" % float(dummy.stats.get("radius", 0.0)))
	quit(0)
