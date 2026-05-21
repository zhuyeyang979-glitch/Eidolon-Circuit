extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_training_config(true)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	if main.game_state != MainScene.STATE_BATTLE:
		_fail("Training should enter battle after seat selection.")
	if main.battle_mode != MainScene.MODE_TRAINING:
		_fail("Battle mode should be training.")
	main._toggle_battle_runtime_menu()
	if main.battle_runtime_menu_panel == null or not main.battle_runtime_menu_panel.visible:
		_fail("Training runtime menu did not open.")
	for key in ["continue", "reset_positions", "reset_resources", "dummy_state", "input", "settings", "training_config", "main_menu"]:
		if not main.battle_runtime_menu_buttons.has(key):
			_fail("Runtime menu missing action: %s" % key)
	var before := String(main.training_dummy_state)
	main._battle_runtime_menu_action("dummy_state")
	var after := String(main.training_dummy_state)
	if before == after:
		_fail("Dummy state option should cycle training dummy state.")
	main._battle_runtime_menu_action("training_config")
	if main.game_state != MainScene.STATE_SCOUT or main.pending_battle_mode != MainScene.MODE_TRAINING:
		_fail("Runtime menu should return to training config.")
	print("TRAINING_PAUSE_OPTIONS_PROBE ok")
	quit()
