extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _function_block(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if source.is_empty():
		_fail("Unable to read main.gd.")
		return
	if not source.contains("func _set_control_text_if_changed") or not source.contains("func _set_canvas_item_visible_if_changed"):
		_fail("TeamEdit no-op property setters are missing.")
		return
	var update_block := _function_block(source, "func _update_editor_ui")
	var dashboard_block := _function_block(source, "func _refresh_editor_dashboard_after_allocation")
	var overlay_block := _function_block(source, "func _editor_perf_overlay_text")
	if update_block.is_empty() or dashboard_block.is_empty() or overlay_block.is_empty():
		_fail("Unable to inspect TeamEdit refresh functions.")
		return
	if not update_block.contains("_set_control_text_if_changed") or not update_block.contains("_set_canvas_item_modulate_if_changed"):
		_fail("_update_editor_ui still bypasses no-op setters on hot labels.")
		return
	if dashboard_block.contains("_update_editor_ui()") or dashboard_block.contains("_update_editor_ui(true)"):
		_fail("Dashboard allocation full refresh still calls _update_editor_ui synchronously.")
		return
	if not dashboard_block.contains("editor_update_ui_deferred = true"):
		_fail("Dashboard allocation full refresh is not deferred.")
		return
	if not overlay_block.contains("editor_visible_control_cached_count") or not overlay_block.contains("editor_visible_control_sample_frame"):
		_fail("Perf overlay still lacks cached visible-control sampling.")
		return
	print("TEAMEDIT_UPDATE_UI_DECOMPOSITION_PROBE ok")
	quit(0)
