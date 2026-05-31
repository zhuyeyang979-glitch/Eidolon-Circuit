extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _mouse_button(pos: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = pos
	event.pressed = pressed
	return event


func _mouse_motion(pos: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = pos
	return event


func _part_is_board_volume(main: Node, role_key: String, slot_key: String, part_index: int) -> bool:
	var part: Dictionary = main._selected_component(role_key, slot_key, part_index)
	if slot_key == "muscle" and main._component_is_torso(part):
		return false
	return true


func _check_part(main: Node, role_key: String, slot_key: String, part_index: int) -> int:
	main.editor_role_index = MainScene.ROLE_ORDER.find(role_key)
	main.editor_board_tool = "layout"
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, slot_key, part_index)
	if not bool(main._has_pending_canvas_part()):
		var part: Dictionary = main._selected_component(role_key, slot_key, part_index)
		_fail("%s %s[%d] %s did not enter pending placement." % [role_key, slot_key, part_index, String(part.get("name", ""))])
	var start := Vector2(312.0, 248.0)
	var drag := start + Vector2(70.0, 35.0)
	main._handle_editor_board_input(_mouse_button(start, true))
	var node_index := int(main.editor_dragging_node_index)
	if node_index < 0:
		var part_no_drag: Dictionary = main._selected_component(role_key, slot_key, part_index)
		_fail("%s %s[%d] %s click placement did not enter drag state." % [role_key, slot_key, part_index, String(part_no_drag.get("name", ""))])
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var before: Vector2 = main._topology_node_position(nodes[node_index])
	main._handle_editor_board_input(_mouse_motion(drag))
	main._handle_editor_board_input(_mouse_button(drag, false))
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var after: Vector2 = main._topology_node_position(nodes[node_index])
	if after.distance_to(before) <= 0.01:
		var failed_part: Dictionary = main._selected_component(role_key, slot_key, part_index)
		_fail("%s %s[%d] %s did not move after real pending click-drag." % [role_key, slot_key, part_index, String(failed_part.get("name", ""))])
	if int(main.editor_dragging_node_index) != -1:
		_fail("%s %s[%d] drag state did not clear on release." % [role_key, slot_key, part_index])
	return 1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	var checked := 0
	for role in MainScene.ROLE_ORDER:
		var role_key := String(role)
		for slot_key in ["limb_muscle", "muscle"]:
			for i in range(main._catalog_for(role_key, slot_key).size()):
				if not _part_is_board_volume(main, role_key, slot_key, i):
					continue
				checked += _check_part(main, role_key, slot_key, i)
	print("BOARD_REAL_PENDING_VOLUMETRIC_DRAG_MATRIX_PROBE ok checked=%d" % checked)
	quit()
