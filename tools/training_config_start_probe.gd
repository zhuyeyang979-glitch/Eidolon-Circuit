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
	if main.game_state != MainScene.STATE_SCOUT:
		_fail("Training config should use scout/config page.")
	if main.pending_battle_mode != MainScene.MODE_TRAINING:
		_fail("Training config should set MODE_TRAINING.")
	main._try_begin_battle_from_scout()
	if main.game_state == MainScene.STATE_BATTLE:
		_fail("Training should not start before P1/P2/P3 seat selection.")
	main._select_ai_battle_seat(3)
	main._try_begin_battle_from_scout()
	if main.game_state != MainScene.STATE_BATTLE:
		_fail("Training should start after seat selection and Start.")
	if main.ai_battle_seat != 3:
		_fail("Training seat should preserve selected P3 spectator mode.")
	print("TRAINING_CONFIG_START_PROBE ok")
	quit()
