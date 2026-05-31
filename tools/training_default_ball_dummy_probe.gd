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
	main._try_begin_battle_from_scout()
	if main.game_state != MainScene.STATE_BATTLE:
		_fail("Training should enter battle with the dedicated ball dummy: %s" % String(main.training_import_error_note))
	var dummy = main.active_units[2]["hero"]
	if not main._is_live_unit(dummy):
		_fail("Training dummy did not spawn.")
	if not bool(dummy.stats.get("training_ball_dummy", false)):
		_fail("Default training dummy should be the dedicated ball dummy.")
	if main._latest_training_dummy_unit_path() != "":
		_fail("Default ball dummy should not depend on a saved Unit4 path.")
	print("TRAINING_DEFAULT_BALL_DUMMY_PROBE ok radius=%.2f" % float(dummy.stats.get("radius", 0.0)))
	quit()
