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
	if not source.contains("const EDITOR_DIRTY_CATALOG") or not source.contains("func mark_editor_dirty") or not source.contains("func flush_editor_dirty"):
		_fail("Editor dirty scheduler symbols are missing.")
		return
	var update_block := _function_block(source, "func _update_editor_ui")
	var flush_block := _function_block(source, "func _flush_editor_deferred_ui")
	var dashboard_block := _function_block(source, "func _refresh_editor_dashboard_after_allocation")
	if update_block.is_empty() or flush_block.is_empty() or dashboard_block.is_empty():
		_fail("Unable to inspect editor dirty scheduler call sites.")
		return
	if not update_block.contains("mark_editor_dirty"):
		_fail("_update_editor_ui same-frame path does not mark dirty flags.")
		return
	if not flush_block.contains("flush_editor_dirty"):
		_fail("_flush_editor_deferred_ui does not drain editor dirty flags.")
		return
	if not dashboard_block.contains("mark_editor_dirty") or dashboard_block.contains("_update_editor_ui(true)"):
		_fail("Dashboard allocation still bypasses dirty scheduling.")
		return
	print("TEAMEDIT_UPDATE_UI_DIRTY_SCHEDULER_PROBE ok")
	quit(0)
