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
	var hot_functions := [
		"func _input",
		"func _handle_editor_input",
		"func _tick_editor_visuals",
	]
	for signature in hot_functions:
		var block := _function_block(source, signature)
		if block.is_empty():
			continue
		if block.contains("_update_editor_ui(true)") or block.contains("_update_editor_ui(false)"):
			_fail("%s still directly calls full editor UI refresh." % signature)
			return
	if not source.contains("mark_editor_dirty(") or not source.contains("flush_editor_dirty("):
		_fail("Dirty editor refresh entrypoints are missing.")
		return
	print("NO_DIRECT_FULL_REFRESH_PROBE ok")
	quit(0)
