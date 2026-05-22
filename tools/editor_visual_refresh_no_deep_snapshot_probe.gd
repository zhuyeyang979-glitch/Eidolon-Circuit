extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _function_block(source: String, signature: String, next_signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find(next_signature, start + signature.length())
	if next < 0 and next_signature == "\n\nfunc ":
		next = source.find("\r\n\r\nfunc ", start + signature.length())
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if source.is_empty():
		_fail("Unable to read main.gd.")
	var key_block := _function_block(source, "func _editor_board_snapshot_cache_key", "\n\nfunc _editor_board_dynamic_revision_key")
	if key_block.is_empty():
		_fail("Base board cache key function missing.")
	for forbidden in ["editor_topology_node_index", "editor_selected_topology_nodes", "editor_selecting_topology_box", "editor_board_zoom", "editor_board_view_offset", "editor_pose_root_node", "editor_dragging_node_index"]:
		if key_block.contains(forbidden):
			_fail("Base board snapshot key still includes dynamic field: %s" % forbidden)
	if not source.contains("func _editor_board_dynamic_revision_key"):
		_fail("Dynamic board revision key helper is missing.")
	if not source.contains("_apply_editor_board_dynamic_fields"):
		_fail("Dynamic board overlay apply helper is missing.")
	if not source.contains("editor_board_base_snapshot_cache"):
		_fail("Base snapshot cache is missing.")
	print("EDITOR_VISUAL_REFRESH_NO_DEEP_SNAPSHOT_PROBE ok")
	quit(0)
