extends SceneTree

const AssemblyBoardViewScript := preload("res://scripts/views/editor/assembly_board_view.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _snapshot(revision: String, select_second: bool) -> Dictionary:
	return {
		"revision_key": revision,
		"view_zoom": 1.0,
		"view_offset": Vector2.ZERO,
		"selected": 0,
		"selected_nodes": [0],
		"nodes": [
			{"pos": Vector2(0.42, 0.5), "slot": "muscle", "material_class": "torso", "is_torso": true, "label": "CORE", "component_length": 0.34, "component_radius": 0.08},
			{"pos": Vector2(0.62, 0.5), "slot": "limb_muscle", "material_class": "muscle", "label": "ARM", "component_length": 0.2, "component_radius": 0.045},
		],
		"edges": [{"a_node": 0, "b_node": 1, "a_socket": "torso_port:0", "b_socket": "root_joint"}],
		"socket_markers": [
			{"node": 0, "slot": "torso_port:0", "pos": Vector2(280, 210), "occupied": true, "selected": false},
			{"node": 1, "slot": "root_joint", "pos": Vector2(360, 210), "occupied": true, "selected": select_second},
		],
		"material_highlights": {},
	}


func _init() -> void:
	var board = AssemblyBoardViewScript.new()
	board.size = Vector2(620.0, 420.0)
	root.add_child(board)
	board.set_board(_snapshot("socket-dirty-1", false), "", {}, "", 0.0, "custom", "zh", 0.0, "socket-dirty-1")
	var initial_sockets := int(board.retained_socket_update_count)
	var initial_edges := int(board.retained_edge_update_count)
	board.set_board(_snapshot("socket-dirty-2", true), "", {}, "", 0.0, "custom", "zh", 0.0, "socket-dirty-2")
	var socket_delta := int(board.retained_socket_update_count) - initial_sockets
	var edge_delta := int(board.retained_edge_update_count) - initial_edges
	if socket_delta != 1:
		_fail("Expected exactly one retained socket update, got %d." % socket_delta)
	if edge_delta != 0:
		_fail("Socket-only update redrew edge items: %d." % edge_delta)
	if int(board.retained_socket_noop_count) <= 0:
		_fail("Unchanged socket did not register no-op.")
	print("RETAINED_SOCKET_DIRTY_UPDATE_PROBE ok socket_delta=%d socket_noops=%d" % [socket_delta, int(board.retained_socket_noop_count)])
	quit(0)
