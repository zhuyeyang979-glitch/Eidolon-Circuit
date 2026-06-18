extends SceneTree

const AssemblyBoardViewScript := preload("res://scripts/views/editor/assembly_board_view.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _snapshot(revision: String, state_one: String) -> Dictionary:
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
		"socket_markers": [],
		"material_highlights": {
			"1": {"state": state_one},
			"2": {"state": "same_limb"},
		},
	}


func _init() -> void:
	var board = AssemblyBoardViewScript.new()
	board.size = Vector2(620.0, 420.0)
	root.add_child(board)
	board.set_board(_snapshot("overlay-dirty-1", "legal_socket"), "", {}, "", 0.0, "custom", "zh", 0.0, "overlay-dirty-1")
	var initial_overlay := int(board.retained_overlay_update_count)
	var initial_edges := int(board.retained_edge_update_count)
	var initial_sockets := int(board.retained_socket_update_count)
	board.set_board(_snapshot("overlay-dirty-2", "illegal_material"), "", {}, "", 0.0, "custom", "zh", 0.0, "overlay-dirty-2")
	var overlay_delta := int(board.retained_overlay_update_count) - initial_overlay
	if overlay_delta != 1:
		_fail("Expected exactly one overlay item update, got %d." % overlay_delta)
	if int(board.retained_edge_update_count) != initial_edges:
		_fail("Overlay-only update redrew edge items.")
	if int(board.retained_socket_update_count) != initial_sockets:
		_fail("Overlay-only update redrew socket items.")
	if int(board.retained_overlay_noop_count) <= 0:
		_fail("Unchanged overlay did not register no-op.")
	print("RETAINED_OVERLAY_DIRTY_UPDATE_PROBE ok overlay_delta=%d overlay_noops=%d" % [overlay_delta, int(board.retained_overlay_noop_count)])
	quit(0)
