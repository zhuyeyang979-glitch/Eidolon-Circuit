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


func _first_limb(main: Node) -> int:
	return 0 if main._catalog_for("hero", "limb_muscle").size() > 0 else -1


func _visible_point(main: Node, unit_bp: Dictionary, node_index: int) -> Vector2:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	return main._topology_position_to_board_local(main._topology_node_position(nodes[node_index]))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_board_tool = "pose"
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, "limb_muscle", _first_limb(main))
	var node_index := main._add_topology_node_at(Vector2(310.0, 250.0))
	if node_index < 0:
		_fail("Could not place unconnected limb.")
	var click_pos := _visible_point(main, unit_bp, node_index)
	main._handle_editor_board_input(_mouse_button(click_pos, true))
	if bool(main.editor_pose_dragging):
		_fail("Unconnected part incorrectly started pose drag.")
	if int(main.editor_dragging_node_index) != node_index:
		_fail("Unconnected pose click should temporarily move the loose part; reject=%s hit=%s." % [String(main.last_layout_drag_reject_reason), String(main.last_layout_drag_hit_reason)])
	var hint := String(main.editor_board_hint_label.text) if main.editor_board_hint_label != null else ""
	if not (hint.contains("未连接") or hint.to_lower().contains("loose")):
		_fail("Unconnected pose temporary-move hint was not shown: %s" % hint)
	print("POSE_MODE_UNCONNECTED_PART_HINT_PROBE ok hint=%s" % hint)
	quit()
