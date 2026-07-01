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
	var block := _function_block(source, "func _refresh_editor_visual_views(")
	if block.is_empty():
		_fail("Missing _refresh_editor_visual_views.")
		return
	var barrier_block := _function_block(source, "func _editor_barrier_screen_board_snapshot(")
	if barrier_block.is_empty():
		_fail("Missing _editor_barrier_screen_board_snapshot helper.")
		return
	if block.contains("topology.duplicate(true)"):
		_fail("TeamEdit visual refresh still deep-copies full topology.")
		return
	if not block.contains("duplicate(false)") or not block.contains("editor_board_shallow_node_snapshot_count"):
		_fail("TeamEdit visual refresh does not use the shallow node snapshot path.")
		return
	if not block.contains("_editor_barrier_screen_board_snapshot(role_key, unit_bp)"):
		_fail("TeamEdit visual refresh should delegate barrier screen board snapshot building.")
		return
	for stale_fragment in [
		"terrain_preview_tiles_by_index",
		"snapshot[\"barrier_columns\"]",
		"snapshot[\"tile_%d\" % i]",
	]:
		if block.contains(stale_fragment):
			_fail("TeamEdit visual refresh should not inline barrier snapshot construction: %s" % stale_fragment)
			return
	for token in [
		"_barrier_terrain_editor_preview",
		"BARRIER_MAP_COLUMNS",
		"BARRIER_BLUEPRINT_WIDTH",
		"editor_board_zoom",
		"editor_board_view_offset",
		"editor_barrier_grid_guides_enabled",
		"_barrier_tile_screen_pos",
		"_selected_component",
		"terrain_preview",
		"revision_key",
	]:
		if not barrier_block.contains(token):
			_fail("Barrier screen board snapshot helper missing token: %s" % token)
			return
	print("EDITOR_VISUAL_REFRESH_NO_DEEP_SNAPSHOT_PROBE ok")
	quit(0)
