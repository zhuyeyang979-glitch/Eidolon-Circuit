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
	var block := _function_block(source, "func _refresh_editor_visual_views")
	if block.is_empty():
		_fail("Missing _refresh_editor_visual_views.")
		return
	if block.contains("topology.duplicate(true)"):
		_fail("TeamEdit visual refresh still deep-copies full topology.")
		return
	if not block.contains("duplicate(false)") or not block.contains("editor_board_shallow_node_snapshot_count"):
		_fail("TeamEdit visual refresh does not use the shallow node snapshot path.")
		return
	print("EDITOR_VISUAL_REFRESH_NO_DEEP_SNAPSHOT_PROBE ok")
	quit(0)
