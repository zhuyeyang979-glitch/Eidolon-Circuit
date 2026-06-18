extends SceneTree

const AssemblyBoardViewScript := preload("res://scripts/views/editor/assembly_board_view.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _snapshot(revision: String, invalid_first: bool) -> Dictionary:
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
		"edge_states": {"0:1": {"invalid": invalid_first}},
		"socket_markers": [],
	}


func _init() -> void:
	var board = AssemblyBoardViewScript.new()
	board.size = Vector2(620.0, 420.0)
	root.add_child(board)
	board.set_board(_snapshot("edge-dirty-1", false), "", {}, "", 0.0, "custom", "zh", 0.0, "edge-dirty-1")
	var initial_edges := int(board.retained_edge_update_count)
	var initial_components := int(board.retained_component_update_count)
	board.set_board(_snapshot("edge-dirty-2", true), "", {}, "", 0.0, "custom", "zh", 0.0, "edge-dirty-2")
	var edge_delta := int(board.retained_edge_update_count) - initial_edges
	var component_delta := int(board.retained_component_update_count) - initial_components
	if edge_delta != 1:
		_fail("Expected exactly one retained edge update, got %d." % edge_delta)
	if component_delta != 0:
		_fail("Edge-only state change redrew component items: %d." % component_delta)
	if int(board.retained_edge_noop_count) <= 0:
		_fail("Unchanged edge did not register no-op.")
	print("RETAINED_EDGE_DIRTY_UPDATE_PROBE ok edge_delta=%d edge_noops=%d" % [edge_delta, int(board.retained_edge_noop_count)])
	quit(0)
