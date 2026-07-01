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
	var shallow_block := _function_block(source, "func _editor_shallow_topology_snapshot(")
	if shallow_block.is_empty():
		_fail("Missing _editor_shallow_topology_snapshot helper.")
		return
	var edge_state_block := _function_block(source, "func _editor_topology_edge_state_snapshot(")
	if edge_state_block.is_empty():
		_fail("Missing _editor_topology_edge_state_snapshot helper.")
		return
	var custom_cache_block := _function_block(source, "func _cache_editor_custom_board_snapshot(")
	if custom_cache_block.is_empty():
		_fail("Missing _cache_editor_custom_board_snapshot helper.")
		return
	var submit_block := _function_block(source, "func _submit_editor_visual_snapshot(")
	if submit_block.is_empty():
		_fail("Missing _submit_editor_visual_snapshot helper.")
		return
	if block.contains("topology.duplicate(true)"):
		_fail("TeamEdit visual refresh still deep-copies full topology.")
		return
	if not block.contains("_editor_shallow_topology_snapshot(topology)"):
		_fail("TeamEdit visual refresh should delegate shallow topology snapshot building.")
		return
	if not block.contains("_editor_barrier_screen_board_snapshot(role_key, unit_bp)"):
		_fail("TeamEdit visual refresh should delegate barrier screen board snapshot building.")
		return
	if not block.contains("_editor_topology_edge_state_snapshot(role_key, unit_bp, nodes, source_nodes_for_edges, source_edges_for_conflicts)"):
		_fail("TeamEdit visual refresh should delegate topology edge-state snapshot building.")
		return
	if not block.contains("_cache_editor_custom_board_snapshot(snapshot, custom_board_cache_key, snapshot_build_start)"):
		_fail("TeamEdit visual refresh should delegate custom board cache writes.")
		return
	if not block.contains("_submit_editor_visual_snapshot(snapshot, board_mode, illegal_parts, update_side_panels)"):
		_fail("TeamEdit visual refresh should delegate board snapshot submission.")
		return
	for stale_fragment in [
		"var source_nodes_raw",
		"var source_edges_raw",
		"var shallow_nodes",
		"var shallow_edges",
		"var endpoint_conflicts",
		"var edge_states := {}",
		"for edge in Array(topology.get(\"edges\", []))",
		"editor_board_base_snapshot_cache =",
		"editor_board_base_snapshot_cache_key =",
		"editor_board_snapshot_cache =",
		"editor_board_snapshot_cache_key =",
		"editor_board_base_snapshot_rebuild_count +=",
		"editor_board_snapshot_rebuild_count +=",
		"var board_revision_key",
		"assembly_board_view.set_board(",
		"hot_path_profiler.record_value(\"teamedit.visual_refresh_usec\"",
		"terrain_preview_tiles_by_index",
		"snapshot[\"barrier_columns\"]",
		"snapshot[\"tile_%d\" % i]",
	]:
		if block.contains(stale_fragment):
			_fail("TeamEdit visual refresh should not inline snapshot construction: %s" % stale_fragment)
			return
	for token in [
		"duplicate(false)",
		"editor_board_shallow_node_snapshot_count",
		"TOPOLOGY_BOARD_PHYSICAL_UNITS",
		"nodes",
		"edges",
	]:
		if not shallow_block.contains(token):
			_fail("Shallow topology snapshot helper missing token: %s" % token)
			return
	for token in [
		"_topology_endpoint_conflicts",
		"_topology_edge_socket_board_points",
		"_topology_edge_can_connect",
		"TOPOLOGY_EDGE_TOLERANCE",
		"edge_states",
		"nodes",
		"invalid",
		"material_error",
	]:
		if not edge_state_block.contains(token):
			_fail("Topology edge-state snapshot helper missing token: %s" % token)
			return
	for token in [
		"editor_board_base_snapshot_cache",
		"editor_board_base_snapshot_cache_key",
		"editor_board_snapshot_cache",
		"editor_board_snapshot_cache_key",
		"editor_board_snapshot_build_usec",
		"editor_board_base_snapshot_rebuild_count",
		"editor_board_snapshot_rebuild_count",
		"Time.get_ticks_usec()",
		"duplicate(false)",
	]:
		if not custom_cache_block.contains(token):
			_fail("Custom board cache helper missing token: %s" % token)
			return
	for token in [
		"assembly_board_view.set_board",
		"editor_selected_body_part",
		"illegal_parts",
		"editor_snap_part",
		"editor_snap_timer",
		"ui_language",
		"editor_canvas_motion_phase",
		"_refresh_editor_orientation_popup",
		"_refresh_torso_detail_view",
		"_refresh_engine_momentum_allocation_view",
		"hot_path_profiler.record_value",
		"hot_path_profiler.scope_end",
	]:
		if not submit_block.contains(token):
			_fail("Board visual snapshot submit helper missing token: %s" % token)
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
