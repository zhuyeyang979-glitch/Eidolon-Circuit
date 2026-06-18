extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _button(root_node: Node, button_name: String) -> Button:
	return root_node.find_child(button_name, true, false) as Button


func _init() -> void:
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/main.gd"))
	for token in [
		"var training_intent_key := \"\"",
		"var scout_training_intent_buttons: Array = []",
		"func _training_intent_specs() -> Array",
		"func _select_training_intent_key",
		"\"intent_source\": \"player\" if training_intent_key != \"\" else \"auto\"",
	]:
		if source.find(token) < 0:
			_fail("Main training intent selector integration missing token: %s" % token)
			return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_training_config(true)
	if main.game_state != MainScene.STATE_SCOUT:
		_fail("Training config should open scout page.")
	if main.training_intent_key != "":
		_fail("Training intent should default to auto/inferred.")

	var auto_button := _button(main.scout_layer, "ScoutIntentAuto")
	var ranged_button := _button(main.scout_layer, "ScoutIntentRangedPressure")
	var burst_button := _button(main.scout_layer, "ScoutIntentCloseBurst")
	if auto_button == null or ranged_button == null or burst_button == null:
		_fail("Training intent selector buttons should exist.")
	if not auto_button.visible or not ranged_button.visible or not burst_button.visible:
		_fail("Training intent selector buttons should be visible in training config.")
	var auto_report: Dictionary = main._training_validation_report_for_current_training()
	if String(auto_report.get("intent_source", "")) != "auto":
		_fail("Default training report should be auto-observed: %s" % str(auto_report))
	var auto_text := String(main.scout_detail_view.detail_text)
	if auto_text.find("系统观察") < 0 and auto_text.find("Observed Intent") < 0:
		_fail("Auto report text should mark inferred intent, got: %s" % auto_text)

	ranged_button.pressed.emit()
	if main.training_intent_key != "ranged_pressure":
		_fail("Ranged intent button should set training_intent_key.")
	var ranged_report: Dictionary = main._training_validation_report_for_current_training()
	if String(ranged_report.get("intent_key", "")) != "ranged_pressure" or String(ranged_report.get("intent_source", "")) != "player":
		_fail("Player-selected ranged intent should override report intent: %s" % str(ranged_report))
	var ranged_text := String(main.scout_detail_view.detail_text)
	if ranged_text.find("玩家目标") < 0 or ranged_text.find("远程压制") < 0:
		_fail("Report detail should show player-selected ranged goal, got: %s" % ranged_text)

	auto_button.pressed.emit()
	if main.training_intent_key != "":
		_fail("Auto intent button should clear player override.")
	var reset_report: Dictionary = main._training_validation_report_for_current_training()
	if String(reset_report.get("intent_source", "")) != "auto":
		_fail("Auto intent button should restore auto intent source: %s" % str(reset_report))

	root.remove_child(main)
	main.free()
	print("TRAINING_VALIDATION_INTENT_SELECTOR_PROBE ok")
	quit(0)
