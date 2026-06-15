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

	var sparring_button := main.scout_layer.find_child("ScoutDummyStateSparring", true, false) as Button
	if sparring_button == null or not sparring_button.visible:
		_fail("Training config should expose a visible computer sparring opponent state.")
		return
	sparring_button.pressed.emit()
	if main.training_dummy_state != "sparring":
		_fail("Sparring button should select the deterministic computer opponent state.")
		return

	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	if main.game_state != MainScene.STATE_BATTLE or main.battle_mode != MainScene.MODE_TRAINING:
		_fail("Sparring setup should enter Training battle mode.")
		return
	var player = main.active_units[1]["hero"]
	var opponent = main.active_units[2]["hero"]
	if not main._is_live_unit(player) or not main._is_live_unit(opponent):
		_fail("Training sparring should spawn both the player unit and computer opponent.")
		return
	if bool(opponent.stats.get("training_ball_dummy", false)):
		_fail("Sparring state should use a combat-capable unit instead of the measurement ball.")
		return
	if float(opponent.stats.get("speed", 0.0)) <= 0.0:
		_fail("Training sparring opponent should be able to move: %s" % str({
			"name": opponent.stats.get("name", ""),
			"move_momentum": opponent.stats.get("move_momentum", 0.0),
			"speed": opponent.stats.get("speed", 0.0),
			"drive": opponent.stats.get("drive_output_total", 0.0),
			"demand": opponent.stats.get("drive_demand_total", 0.0),
		}))
		return
	if main._ai_best_attack_reach(opponent, "normal") <= 0.0:
		_fail("Training sparring opponent should expose at least one usable attack group.")
		return

	player.ring_pos = 2.0
	player.lane = 0.0
	opponent.ring_pos = 5.0
	opponent.lane = 0.4
	var before := Vector2(opponent.ring_pos, opponent.lane)
	for i in range(10):
		main._update_training_dummy(0.1)
		main._update_units(0.1, false)
	var after := Vector2(opponent.ring_pos, opponent.lane)
	if after.distance_to(before) <= 0.001:
		_fail("Computer sparring opponent should actively move under deterministic battle rules.")
		return

	main._toggle_battle_runtime_menu()
	var model: Dictionary = main.menu_controller.battle_runtime_model(main.ui_language, main.battle_mode, MainScene.MODE_TRAINING, main.training_dummy_state)
	var saw_sparring_label := false
	for raw_item in Array(model.get("items", [])):
		if raw_item is Dictionary and String(Dictionary(raw_item).get("key", "")) == "dummy_state":
			var label := String(Dictionary(raw_item).get("label", ""))
			saw_sparring_label = label.find("电脑陪练") >= 0 or label.to_lower().find("sparring") >= 0
	if not saw_sparring_label:
		_fail("Training runtime menu should identify the computer sparring state.")
		return

	print("TRAINING_SPARRING_OPPONENT_PROBE ok")
	quit()
