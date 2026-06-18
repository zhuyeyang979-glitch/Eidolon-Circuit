extends SceneTree

const AssemblyBoardViewScript := preload("res://scripts/views/editor/assembly_board_view.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _snapshot(revision: String) -> Dictionary:
	return {
		"revision_key": revision,
		"view_zoom": 1.0,
		"view_offset": Vector2.ZERO,
		"selected": 0,
		"selected_nodes": [0],
		"nodes": [
			{"pos": Vector2(0.38, 0.5), "slot": "muscle", "material_class": "torso", "is_torso": true, "label": "CORE", "component_length": 0.34, "component_radius": 0.08},
			{"pos": Vector2(0.58, 0.44), "slot": "limb_muscle", "material_class": "muscle", "label": "ARM A", "component_length": 0.2, "component_radius": 0.045},
			{"pos": Vector2(0.58, 0.62), "slot": "limb_muscle", "material_class": "muscle", "label": "ARM B", "component_length": 0.2, "component_radius": 0.045},
		],
		"edges": [
			{"a_node": 0, "b_node": 1, "a_socket": "torso_port:0", "b_socket": "root_joint"},
			{"a_node": 0, "b_node": 2, "a_socket": "torso_port:1", "b_socket": "root_joint"},
		],
		"edge_states": {},
		"socket_markers": [
			{"node": 0, "slot": "torso_port:0", "pos": Vector2(280, 210), "occupied": true},
			{"node": 1, "slot": "root_joint", "pos": Vector2(360, 190), "selected": true},
		],
		"material_highlights": {"1": {"state": "legal_socket"}},
		"material_warning_nodes": [2],
		"joint_slot_profiles": [{"pivot": Vector2(0.38, 0.5), "world_center_angle": 0.0, "half_width": 0.4}],
		"candidate_socket_pair": {"a": Vector2(290, 240), "b": Vector2(360, 245)},
	}


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/views/editor/assembly_board_view.gd")
	if source.is_empty() or not source.contains("class_name AssemblyBoardView"):
		_fail("Unable to read extracted AssemblyBoardView.")
	var layer_block_start := source.find("class AssemblyBoardRenderLayer")
	var layer_block_end := source.find("class AssemblyBoardRenderComponentItem", layer_block_start)
	if layer_block_start < 0 or layer_block_end < 0:
		_fail("Retained layer class block not found.")
	var layer_block := source.substr(layer_block_start, layer_block_end - layer_block_start)
	if layer_block.contains("\"edges\"") or layer_block.contains("\"sockets\"") or layer_block.contains("\"overlays\""):
		_fail("Retained edge/socket/overlay containers still draw whole layers.")
	var board = AssemblyBoardViewScript.new()
	board.size = Vector2(620.0, 420.0)
	root.add_child(board)
	board.set_board(_snapshot("retained-items-1"), "", {}, "", 0.0, "custom", "zh", 0.0, "retained-items-1")
	if board.retained_edge_items.size() != 2:
		_fail("Expected 2 retained edge items, got %d." % board.retained_edge_items.size())
	if board.retained_socket_items.size() != 2:
		_fail("Expected 2 retained socket items, got %d." % board.retained_socket_items.size())
	if board.retained_material_overlay_items.size() != 1 or board.retained_warning_items.size() != 1 or board.retained_sweep_arc_items.size() != 1 or board.retained_candidate_socket_items.size() != 1:
		_fail("Overlay retained item pools were not populated as expected.")
	if int(board.retained_full_draw_fallback_count) != 0:
		_fail("Monolithic board fallback was used.")
	print("EDGE_SOCKET_OVERLAY_RETAINED_ITEMS_PROBE ok edges=%d sockets=%d overlays=%d" % [
		board.retained_edge_items.size(),
		board.retained_socket_items.size(),
		board.retained_material_overlay_items.size() + board.retained_warning_items.size() + board.retained_sweep_arc_items.size() + board.retained_candidate_socket_items.size(),
	])
	quit(0)
