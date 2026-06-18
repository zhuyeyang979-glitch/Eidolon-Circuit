extends SceneTree

const AssemblyBoardViewScript := preload("res://scripts/views/editor/assembly_board_view.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _snapshot(revision: String, arm_pos: Vector2, selected_nodes: Array = [0]) -> Dictionary:
	return {
		"revision_key": revision,
		"view_zoom": 1.0,
		"view_offset": Vector2.ZERO,
		"selected": selected_nodes[0] if selected_nodes.size() > 0 else 0,
		"selected_nodes": selected_nodes,
		"nodes": [
			{
				"pos": Vector2(0.44, 0.5),
				"slot": "muscle",
				"material_class": "torso",
				"is_torso": true,
				"label": "CORE",
				"component_length": 0.34,
				"component_radius": 0.08,
				"component_mass": 14.0,
				"module_slots": 2,
				"torso_slots": 2,
			},
			{
				"pos": arm_pos,
				"slot": "limb_muscle",
				"material_class": "muscle",
				"label": "ARM",
				"component_length": 0.22,
				"component_radius": 0.045,
				"component_mass": 3.0,
			},
			{
				"pos": Vector2(0.24, 0.68),
				"slot": "limb_muscle",
				"material_class": "muscle",
				"label": "FREE",
				"component_length": 0.18,
				"component_radius": 0.04,
				"component_mass": 2.0,
			},
		],
		"edges": [{"a_node": 0, "b_node": 1, "a_socket": "torso_port:0", "b_socket": "root_joint"}],
		"edge_states": {},
		"socket_markers": [],
	}


func _init() -> void:
	var board = AssemblyBoardViewScript.new()
	board.size = Vector2(620.0, 420.0)
	root.add_child(board)
	board.set_board(_snapshot("dirty-1", Vector2(0.63, 0.5)), "", {}, "", 0.0, "custom", "zh", 0.0, "dirty-1")
	var initial_updates := int(board.retained_component_update_count)
	board.set_board(_snapshot("dirty-1", Vector2(0.63, 0.5)), "", {}, "", 0.0, "custom", "zh", 0.0, "dirty-1")
	if int(board.retained_component_update_count) != initial_updates:
		_fail("Identical board changed retained component update count.")
	var changed_snapshot := _snapshot("dirty-2", Vector2(0.63, 0.5))
	changed_snapshot["nodes"][2]["pos"] = Vector2(0.3, 0.72)
	board.set_board(changed_snapshot, "", {}, "", 0.0, "custom", "zh", 0.0, "dirty-2")
	var changed_updates := int(board.retained_component_update_count) - initial_updates
	var changed_noops := int(board.retained_component_noop_count)
	if changed_updates != 1:
		_fail("Expected only one component redraw after one node moved, got %d." % changed_updates)
	if changed_noops <= 0:
		_fail("Unchanged retained component did not register no-op.")
	var selection_snapshot := _snapshot("dirty-3", Vector2(0.63, 0.5), [1])
	selection_snapshot["nodes"][2]["pos"] = Vector2(0.3, 0.72)
	board.set_board(selection_snapshot, "", {}, "", 0.0, "custom", "zh", 0.0, "dirty-3")
	if int(board.retained_component_update_count) - initial_updates > 3:
		_fail("Selection-only update redrew too many component items.")
	print("BOARD_SEGMENT_DIRTY_UPDATE_PROBE ok updates=%d noops=%d" % [
		int(board.retained_component_update_count),
		int(board.retained_component_noop_count),
	])
	quit(0)
