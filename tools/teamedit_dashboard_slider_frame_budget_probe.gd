extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _function_block_between(source: String, signature: String, next_signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find(next_signature, start + signature.length())
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if source.is_empty():
		_fail("Unable to read main.gd.")
	var light_block := _function_block_between(source, "func _refresh_editor_dashboard_after_allocation", "func _equalize_engine_momentum_allocation")
	if light_block.is_empty():
		_fail("Dashboard allocation refresh helper missing.")
	var full_branch := light_block.substr(0, light_block.find("editor_allocation_light_refresh_count"))
	var light_branch := light_block.substr(light_block.find("editor_allocation_light_refresh_count"))
	if light_branch.contains("_refresh_editor_visual_views("):
		_fail("Dashboard allocation light refresh still touches board visuals.")
	if light_branch.contains("_update_editor_ui("):
		_fail("Dashboard allocation light refresh still calls full _update_editor_ui.")
	var setter_block := _function_block_between(source, "func _set_engine_momentum_allocation_ratio", "func _finish_engine_momentum_allocation_drag")
	if setter_block.contains("_update_editor_ui("):
		_fail("Allocation slider setter still calls full _update_editor_ui.")
	print("TEAMEDIT_DASHBOARD_SLIDER_FRAME_BUDGET_PROBE ok")
	quit(0)
