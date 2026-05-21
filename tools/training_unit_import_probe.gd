extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._legalize_ai_player_roster(1, true)
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = main._blueprint_for(1, "hero", 0).duplicate(true)
	main.editor_working_blueprint["unit_name"] = "Training Probe Unsaved Canvas"
	main.editor_working_blueprint["blank_canvas"] = false
	main._import_editor_canvas_to_training()
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	if Dictionary(main.training_import_blueprint.get("entry_pose", {})).is_empty():
		_fail("Training import should preserve the current canvas entry pose.")
	if main.game_state != MainScene.STATE_BATTLE or main.battle_mode != MainScene.MODE_TRAINING:
		_fail("Training import should enter battle training mode.")
	var p1_units: Dictionary = main.active_units.get(1, {})
	if p1_units.get("hero", null) == null and Array(p1_units.get("puppet", [])).is_empty() and p1_units.get("barrier", null) == null:
		_fail("Training import did not spawn the imported P1 unit.")
	print("TRAINING_UNIT_IMPORT_PROBE ok role=%s state=%s" % [main.training_import_role_key, main.game_state])
	quit()
