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
	var bp: Dictionary = main._editor_current_blueprint()
	bp["custom_topology"] = main._default_free_canvas_topology("hero")
	bp["blank_canvas"] = false
	bp["power"] = 9.0
	var name := "Strict Reject Probe %d" % int(Time.get_ticks_msec())
	var path := main._save_editor_current_unit_to_library_named(name, "", true)
	if path != "":
		_fail("Legacy blueprint was silently repaired and saved.")
		return
	var feedback := String(main.editor_save_unit_feedback_label.text) if main.editor_save_unit_feedback_label != null else ""
	if feedback.find("legacy drive/pointer field") < 0 or feedback.find("power") < 0:
		_fail("Strict rejection did not name the blocking legacy path: %s" % feedback)
		return
	print("SAVED_UNIT_STRICT_REJECTION_PROBE ok feedback=%s" % feedback)
	quit()
