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
	main._update_editor_ui(true)
	main._set_editor_perf_overlay_enabled(true)
	var text := main._editor_perf_overlay_text()
	for required in ["update_ui", "prop write/noop", "ui full/deferred/alloc", "visible controls"]:
		if not text.contains(required):
			_fail("TeamEdit perf overlay missing trace field: %s" % required)
			return
	var sample_before := int(main.editor_visible_control_sample_frame)
	main._editor_perf_overlay_text()
	var sample_after := int(main.editor_visible_control_sample_frame)
	if sample_after != sample_before:
		_fail("Perf overlay visible-control count resampled on consecutive calls.")
		return
	print("TEAMEDIT_TRACE_PROFILER_PROBE ok")
	quit(0)
