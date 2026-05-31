extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = main._make_editor_blank_blueprint("hero")
	main._start_editor_canvas_training_test()
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Illegal training test should keep the player in Unit Edit.")
	var expected_note := main._training_blueprint_illegal_note(main._editor_player(), "hero", main._unit_blueprint_for_library("hero", main._editor_current_blueprint()))
	if expected_note == "":
		_fail("Blank unit unexpectedly has no training illegal note.")
	var localized := main._localized_system_text(expected_note)
	var summary: String = main.editor_summary_label.text if main.editor_summary_label != null else ""
	var hint: String = main.editor_board_hint_label.text if main.editor_board_hint_label != null else ""
	var feedback: String = main.editor_save_unit_feedback_label.text if main.editor_save_unit_feedback_label != null else ""
	if summary.find(localized) < 0:
		_fail("Summary did not show illegal training reason: %s" % summary)
	if hint.find(localized) < 0:
		_fail("Board hint did not show illegal training reason: %s" % hint)
	if feedback.find(localized) < 0 or not main.editor_save_unit_feedback_label.visible:
		_fail("Visible feedback did not show illegal training reason: %s" % feedback)
	if not main.editor_save_feedback_is_error:
		_fail("Training illegal feedback should be marked as an error.")
	print("UNIT_EDITOR_TRAINING_ILLEGAL_FEEDBACK_PROBE ok reason=%s" % localized)
	quit()
