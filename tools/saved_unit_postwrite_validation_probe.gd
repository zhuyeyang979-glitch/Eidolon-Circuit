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
	main._show_editor(true)
	var unit_name := "Invalid Save Probe %d" % int(Time.get_ticks_msec())
	var bp: Dictionary = main._editor_current_blueprint()
	bp["custom_topology"] = {"nodes": [], "edges": []}
	bp["blank_canvas"] = false
	bp["unit_name"] = unit_name
	var before_source := String(main.editor_source_saved_unit_path)
	var saved_path := main._save_editor_current_unit_to_library_named(unit_name)
	if saved_path != "":
		_fail("Invalid save should not return a saved path.")
		return
	if String(main.editor_source_saved_unit_path) != before_source:
		_fail("Invalid save should not update editor source path.")
		return
	if main.editor_save_unit_feedback_label == null or not main.editor_save_unit_feedback_label.visible:
		_fail("Invalid save should show feedback.")
		return
	var feedback := String(main.editor_save_unit_feedback_label.text)
	if feedback.find("Save failed") < 0 and feedback.find("保存失败") < 0:
		_fail("Invalid save did not show a save failure: %s" % feedback)
		return
	if not bool(main.editor_save_feedback_is_error):
		_fail("Invalid save feedback should be marked as an error.")
		return
	print("SAVED_UNIT_POSTWRITE_VALIDATION_PROBE ok feedback=%s" % feedback)
	quit(0)
