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
	var enriched_nodes_block := _function_block(source, "func _editor_enriched_topology_nodes_snapshot(")
	if enriched_nodes_block.is_empty():
		_fail("Missing _editor_enriched_topology_nodes_snapshot helper.")
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
	var custom_snapshot_block := _function_block(source, "func _editor_custom_board_snapshot(")
	if custom_snapshot_block.is_empty():
		_fail("Missing _editor_custom_board_snapshot helper.")
		return
	var visual_snapshot_block := _function_block(source, "func _editor_visual_snapshot_for_current_board(")
	if visual_snapshot_block.is_empty():
		_fail("Missing _editor_visual_snapshot_for_current_board helper.")
		return
	var visual_skip_block := _function_block(source, "func _try_skip_editor_visual_refresh(")
	if visual_skip_block.is_empty():
		_fail("Missing _try_skip_editor_visual_refresh helper.")
		return
	var dynamic_overlay_block := _function_block(source, "func _apply_editor_visual_snapshot_dynamic_overlay(")
	if dynamic_overlay_block.is_empty():
		_fail("Missing _apply_editor_visual_snapshot_dynamic_overlay helper.")
		return
	var selected_preview_block := _function_block(source, "func _refresh_editor_visual_selected_part_preview(")
	if selected_preview_block.is_empty():
		_fail("Missing _refresh_editor_visual_selected_part_preview helper.")
		return
	var begin_refresh_block := _function_block(source, "func _begin_editor_visual_refresh(")
	if begin_refresh_block.is_empty():
		_fail("Missing _begin_editor_visual_refresh helper.")
		return
	if block.contains("topology.duplicate(true)"):
		_fail("TeamEdit visual refresh still deep-copies full topology.")
		return
	if block.count("if not _begin_editor_visual_refresh():") != 1:
		_fail("TeamEdit visual refresh should delegate entry gate once.")
		return
	if block.count("_try_skip_editor_visual_refresh(visual_revision, update_side_panels)") != 1:
		_fail("TeamEdit visual refresh should delegate revision skip handling once.")
		return
	if block.count("_refresh_editor_visual_selected_part_preview(update_side_panels)") != 1:
		_fail("TeamEdit visual refresh should delegate selected part preview refresh once.")
		return
	if block.count("_editor_visual_snapshot_for_current_board(role_key, unit_bp, custom_board_cache_key, visual_stats, barrier_screen_board, player_id)") != 1:
		_fail("TeamEdit visual refresh should delegate base board snapshot selection once.")
		return
	if block.count("snapshot = _apply_editor_visual_snapshot_dynamic_overlay(snapshot, board_mode, role_key, unit_bp, custom_board_cache_key, visual_stats)") != 1:
		_fail("TeamEdit visual refresh should delegate dynamic overlay application once.")
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
		"editor_board_node_enrich_count +=",
		"if _topology_node_is_component(node):",
		"node[\"component_length\"]",
		"node[\"joint_length\"]",
		"node[\"downstream_rotation_radius_units\"]",
		"terrain_preview_tiles_by_index",
		"snapshot[\"barrier_columns\"]",
		"snapshot[\"tile_%d\" % i]",
		"editor_board_base_snapshot_hit_count +=",
		"editor_board_snapshot_cache_hit_count +=",
		"editor_board_base_snapshot_cache.duplicate(false)",
		"_editor_custom_board_snapshot(role_key, unit_bp, custom_board_cache_key, visual_stats, player_id)",
		"_editor_barrier_screen_board_snapshot(role_key, unit_bp)",
		"editor_visual_refresh_skip_count +=",
		"hot_path_profiler.count(\"teamedit.visual_refresh.skip\")",
		"var snapshot_build_start",
		"var topology:",
		"snapshot[\"joint_slot_profiles\"]",
		"_board_nodes_with_art_visual_positions",
		"_topology_socket_markers_for_board",
		"_topology_material_highlights_for_board",
		"if board_mode == \"custom\" and not snapshot.is_empty():",
		"_apply_editor_board_dynamic_fields(snapshot, role_key, unit_bp, custom_board_cache_key, visual_stats)",
		"_refresh_editor_selected_part_preview(BUILD_SLOTS[editor_slot_index], selected_component, clampf(editor_snap_timer / 0.28, 0.0, 1.0))",
		"editor_board_visual_request_count +=",
		"hot_path_profiler.scope_begin(\"teamedit.visual_refresh\")",
		"editor_visual_refresh_count +=",
		"if assembly_board_view == null:",
		"hot_path_profiler.scope_end(\"teamedit.visual_refresh\")",
	]:
		if block.contains(stale_fragment):
			_fail("TeamEdit visual refresh should not inline snapshot construction: %s" % stale_fragment)
			return
	for token in [
		"editor_board_visual_request_count +=",
		"hot_path_profiler.scope_begin(\"teamedit.visual_refresh\")",
		"editor_visual_refresh_count +=",
		"if assembly_board_view == null:",
		"hot_path_profiler.scope_end(\"teamedit.visual_refresh\")",
		"return false",
		"return true",
	]:
		if not begin_refresh_block.contains(token):
			_fail("Visual refresh entry helper missing token: %s" % token)
			return
	for token in [
		"_editor_shallow_topology_snapshot(topology)",
		"_compute_unit_stats(player_id, role_key, -1, unit_bp)",
		"joint_slot_profiles",
		"swept_collision_count",
		"_editor_enriched_topology_nodes_snapshot",
		"_board_nodes_with_art_visual_positions",
		"_editor_topology_edge_state_snapshot",
		"_topology_socket_markers_for_board",
		"_topology_material_highlights_for_board",
		"_cache_editor_custom_board_snapshot",
		"\"snapshot\"",
		"\"visual_stats\"",
	]:
		if not custom_snapshot_block.contains(token):
			_fail("Custom board snapshot helper missing token: %s" % token)
			return
	for token in [
		"editor_board_base_snapshot_cache_key",
		"editor_board_base_snapshot_cache",
		"editor_board_base_snapshot_hit_count",
		"editor_board_snapshot_cache_hit_count",
		"duplicate(false)",
		"_editor_custom_board_snapshot(role_key, unit_bp, custom_board_cache_key, visual_stats, player_id)",
		"_editor_barrier_screen_board_snapshot(role_key, unit_bp)",
		"\"snapshot\"",
		"\"visual_stats\"",
		"\"board_mode\"",
	]:
		if not visual_snapshot_block.contains(token):
			_fail("Visual snapshot selection helper missing token: %s" % token)
			return
	for token in [
		"visual_revision == editor_visual_revision_key",
		"editor_visual_refresh_skip_count +=",
		"_refresh_torso_detail_view()",
		"_refresh_engine_momentum_allocation_view()",
		"_refresh_editor_orientation_popup()",
		"hot_path_profiler.count(\"teamedit.visual_refresh.skip\")",
		"hot_path_profiler.scope_end(\"teamedit.visual_refresh\")",
		"return true",
		"return false",
	]:
		if not visual_skip_block.contains(token):
			_fail("Visual refresh skip helper missing token: %s" % token)
			return
	for token in [
		"board_mode == \"custom\"",
		"not snapshot.is_empty()",
		"_apply_editor_board_dynamic_fields(snapshot, role_key, unit_bp, custom_board_cache_key, visual_stats)",
		"return snapshot",
	]:
		if not dynamic_overlay_block.contains(token):
			_fail("Visual dynamic overlay helper missing token: %s" % token)
			return
	for token in [
		"if not update_side_panels:",
		"return",
		"_refresh_editor_selected_part_preview(BUILD_SLOTS[editor_slot_index], selected_component, clampf(editor_snap_timer / 0.28, 0.0, 1.0))",
	]:
		if not selected_preview_block.contains(token):
			_fail("Selected part preview helper missing token: %s" % token)
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
		"_topology_node_is_component",
		"_topology_node_part",
		"_part_with_effective_terminal_geometry",
		"_module_indices_for_topology_node",
		"_component_is_torso",
		"_torso_occupied_port_indices",
		"_topology_joint_max_rotation_radius_units",
		"_apply_visual_handedness_defaults_to_node",
		"editor_board_node_enrich_count",
		"nodes[i] = node",
	]:
		if not enriched_nodes_block.contains(token):
			_fail("Enriched topology nodes helper missing token: %s" % token)
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
