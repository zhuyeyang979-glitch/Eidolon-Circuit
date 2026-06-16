extends SceneTree

const AssemblyBoardViewScript := preload("res://scripts/views/editor/assembly_board_view.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _function_block_after(source: String, anchor: String, signature: String, next_signature: String) -> String:
	var anchor_pos := source.find(anchor)
	if anchor_pos < 0:
		return ""
	var start := source.find(signature, anchor_pos)
	if start < 0:
		return ""
	var next := source.find(next_signature, start + signature.length())
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _sample_snapshot() -> Dictionary:
	return {
		"revision_key": "retained-probe-1",
		"view_zoom": 1.0,
		"view_offset": Vector2.ZERO,
		"selected": 0,
		"selected_nodes": [0],
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
				"pos": Vector2(0.63, 0.5),
				"slot": "limb_muscle",
				"material_class": "muscle",
				"label": "ARM",
				"component_length": 0.22,
				"component_radius": 0.045,
				"component_mass": 3.0,
			},
		],
		"edges": [{"a_node": 0, "b_node": 1, "a_socket": "torso_port:0", "b_socket": "root_joint"}],
		"edge_states": {},
		"socket_markers": [],
	}


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/views/editor/assembly_board_view.gd")
	if source.is_empty():
		_fail("Unable to read assembly_board_view.gd.")
	if not source.contains("class_name AssemblyBoardView") or not source.contains("class AssemblyBoardRenderLayer") or not source.contains("class AssemblyBoardRenderComponentItem"):
		_fail("Retained render layer classes are missing.")
	var draw_block := _function_block_after(source, "signal part_dropped", "func _draw() -> void:", "\nfunc _draw_barrier_board")
	if draw_block.is_empty():
		_fail("AssemblyBoardView._draw block not found.")
	if draw_block.contains("_draw_custom_board()"):
		_fail("AssemblyBoardView._draw still calls monolithic _draw_custom_board for custom boards.")
	var board = AssemblyBoardViewScript.new()
	board.size = Vector2(620.0, 420.0)
	root.add_child(board)
	board.set_board(_sample_snapshot(), "", {}, "", 0.0, "custom", "zh", 0.0, "retained-probe-1")
	if board.retained_render_layer == null or not board.retained_render_layer.visible:
		_fail("Retained render layer was not created or visible for custom board.")
	if board.retained_component_items.size() != 2:
		_fail("Expected two retained component items, got %d." % board.retained_component_items.size())
	if int(board.retained_full_draw_fallback_count) != 0:
		_fail("Monolithic custom board fallback was used during retained setup.")
	print("ASSEMBLY_BOARD_RETAINED_RENDER_PROBE ok components=%d submits=%d" % [
		board.retained_component_items.size(),
		int(board.retained_render_submit_count),
	])
	quit(0)
