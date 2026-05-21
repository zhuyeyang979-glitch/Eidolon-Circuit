extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_torso(main) -> int:
	for i in range(MainScene.COMMON_CATALOG["muscle"].size()):
		var part: Dictionary = MainScene.COMMON_CATALOG["muscle"][i]
		if main._component_is_torso(part):
			return i
	return -1


func _left_click(position: Vector2, double_click: bool = false, pressed: bool = true) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = pressed
	event.double_click = double_click
	return event


func _wheel(position: Vector2, button_index: int) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.position = position
	event.pressed = true
	return event


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var role_key: String = MainScene.ROLE_ORDER[main.editor_role_index]
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var torso_index := _find_torso(main)
	if torso_index < 0:
		_fail("No torso component found for board zoom probe.")
	var topology_pos := Vector2(0.68, 0.42)
	main._set_pending_canvas_part(unit_bp, "muscle", torso_index)
	var torso_node := main._add_topology_node_at(main._topology_position_to_board_local(topology_pos))
	if torso_node != 0:
		_fail("Expected first torso node to be index 0, got %d." % torso_node)
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	if nodes.size() != 1:
		_fail("Expected one topology node, got %d." % nodes.size())
	var stored_pos: Vector2 = main._topology_node_position(Dictionary(nodes[0]))
	if stored_pos.distance_to(topology_pos) > 0.004:
		_fail("Placed torso topology position drifted %.4f." % stored_pos.distance_to(topology_pos))

	var anchor := main._topology_position_to_board_local(stored_pos)
	var roundtrip: Vector2 = main._board_position_to_topology(anchor)
	if roundtrip.distance_to(stored_pos) > 0.004:
		_fail("Initial board/topology roundtrip drifted %.4f." % roundtrip.distance_to(stored_pos))

	main._reset_editor_board_zoom()
	var visual_node_1x: Dictionary = Dictionary(Array(main.assembly_board_view.board_snapshot.get("nodes", []))[0])
	var radius_1x: float = main.assembly_board_view._node_visual_radius(visual_node_1x)
	main._set_editor_board_zoom(2.0, anchor)
	var visual_node_2x: Dictionary = Dictionary(Array(main.assembly_board_view.board_snapshot.get("nodes", []))[0])
	var radius_2x: float = main.assembly_board_view._node_visual_radius(visual_node_2x)
	if radius_2x <= radius_1x * 1.65:
		_fail("Board zoom moved nodes but did not scale part art enough: 1x %.2f, 2x %.2f." % [radius_1x, radius_2x])
	var after_zoom_anchor := main._topology_position_to_board_local(stored_pos)
	if after_zoom_anchor.distance_to(anchor) > 0.75:
		_fail("Cursor-anchored zoom moved the anchored topology point by %.2f px." % after_zoom_anchor.distance_to(anchor))
	if absf(main.editor_board_zoom - 2.0) > 0.001:
		_fail("Board zoom did not store requested zoom.")
	if main.editor_board_zoom_label == null or String(main.editor_board_zoom_label.text) != "200%":
		_fail("Board zoom label did not show 200%%.")

	for zoom in [MainScene.EDITOR_BOARD_ZOOM_MIN, 1.0, MainScene.EDITOR_BOARD_ZOOM_MAX]:
		main._set_editor_board_zoom(float(zoom), main._topology_position_to_board_local(stored_pos))
		var hit_point := main._topology_position_to_board_local(stored_pos)
		var hit := main._nearest_custom_node_index(role_key, unit_bp, nodes, hit_point)
		if hit != 0:
			_fail("Nearest-node hit failed at zoom %.2f; got %d." % [float(zoom), hit])

	main._set_editor_board_zoom(1.0, main._topology_position_to_board_local(stored_pos))
	var current_zoom: float = float(main.editor_board_zoom)
	main.editor_dragging_node_index = 0
	main._handle_editor_board_input(_wheel(main._topology_position_to_board_local(stored_pos), MOUSE_BUTTON_WHEEL_UP))
	if absf(main.editor_board_zoom - current_zoom) > 0.001:
		_fail("Wheel zoom changed while a node drag was active.")
	main.editor_dragging_node_index = -1
	main._handle_editor_board_input(_wheel(main._topology_position_to_board_local(stored_pos), MOUSE_BUTTON_WHEEL_UP))
	if main.editor_board_zoom <= current_zoom:
		_fail("Wheel zoom did not increase when the board was idle.")

	main._reset_editor_board_zoom()
	var click_pos := main._topology_position_to_board_local(stored_pos)
	main.editor_open_torso_node_index = -1
	main._handle_editor_board_input(_left_click(click_pos, false, true))
	if main.editor_open_torso_node_index != -1:
		_fail("Single-click torso opened the torso detail panel.")
	if main.editor_dragging_node_index != 0:
		_fail("Single-click torso did not start normal node dragging.")
	main._handle_editor_board_input(_left_click(click_pos, false, false))
	if main.editor_dragging_node_index != -1:
		_fail("Mouse release did not end torso drag.")

	main._handle_editor_board_input(_left_click(click_pos, true, true))
	if main.editor_open_torso_node_index != 0:
		_fail("Double-click torso did not open the torso detail panel.")
	if main.editor_dragging_node_index != -1 or main.editor_dragging_whole_unit:
		_fail("Double-click torso left a drag operation active.")

	main.editor_hover_slot_key = ""
	main._update_editor_board_torso_hover(click_pos)
	if main.editor_hovered_torso_node_index != 0:
		_fail("Torso hover did not highlight the torso node.")
	if String(main.editor_hover_slot_key) == "torso_node":
		_fail("Torso hover still opened the full torso hover card.")

	print("EDITOR_BOARD_ZOOM_PROBE node=%d zoom=%.2f label=%s hover=%d" % [
		torso_node,
		main.editor_board_zoom,
		String(main.editor_board_zoom_label.text),
		main.editor_hovered_torso_node_index,
	])
	quit()
