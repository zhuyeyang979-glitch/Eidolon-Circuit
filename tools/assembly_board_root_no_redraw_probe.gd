extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _sample_snapshot() -> Dictionary:
	return {
		"revision_key": "root-no-redraw",
		"view_zoom": 1.0,
		"view_offset": Vector2.ZERO,
		"selected": 0,
		"selected_nodes": [0],
		"nodes": [
			{"pos": Vector2(0.45, 0.5), "slot": "muscle", "material_class": "torso", "is_torso": true, "label": "CORE", "component_length": 0.32, "component_radius": 0.08},
			{"pos": Vector2(0.62, 0.5), "slot": "limb_muscle", "material_class": "muscle", "label": "ARM", "component_length": 0.24, "component_radius": 0.04},
		],
		"edges": [{"a_node": 0, "b_node": 1, "a_socket": "torso_port:0", "b_socket": "root_joint"}],
		"edge_states": {},
		"socket_markers": [],
	}


func _init() -> void:
	var board = MainScene.AssemblyBoardView.new()
	board.size = Vector2(640.0, 420.0)
	root.add_child(board)
	board.set_board(_sample_snapshot(), "", {}, "", 0.0, "custom", "zh", 0.0, "root-no-redraw")
	if board.retained_render_layer == null:
		_fail("Custom board did not create retained render layer.")
	if int(board.root_redraw_request_count) != 0:
		_fail("Custom retained set_board requested root redraw %d times." % int(board.root_redraw_request_count))
	if int(board.custom_retained_root_redraw_skip_count) <= 0:
		_fail("Custom retained set_board did not record root redraw skip.")
	if int(board.retained_full_draw_fallback_count) != 0:
		_fail("Custom retained board used monolithic fallback draw.")
	print("ASSEMBLY_BOARD_ROOT_NO_REDRAW_PROBE ok skips=%d applies=%d" % [
		int(board.custom_retained_root_redraw_skip_count),
		int(board.set_board_apply_count),
	])
	quit(0)
