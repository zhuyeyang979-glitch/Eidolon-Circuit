extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _scythe_index(main: Node) -> int:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._blade_weapon_family_for_part(part) == "scythe" and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return -1


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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var scythe_part := _scythe_index(main)
	if scythe_part < 0:
		_fail("Scythe terminal missing.")
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, "muscle", scythe_part)
	var start := Vector2(290.0, 246.0)
	main._handle_editor_board_input(_mouse_button(start, true))
	var node_index := int(main.editor_dragging_node_index)
	if node_index < 0:
		_fail("Click-placement did not enter node adjustment drag state.")
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var before_pos: Vector2 = main._topology_node_position(nodes[node_index])
	main._handle_editor_board_input(_mouse_motion(start + Vector2(90.0, 42.0)))
	main._handle_editor_board_input(_mouse_button(start + Vector2(90.0, 42.0), false))
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var after_pos: Vector2 = main._topology_node_position(nodes[node_index])
	if after_pos.distance_to(before_pos) <= 0.01:
		_fail("Click-placed scythe did not continue dragging to the adjusted position.")
	if int(main.editor_dragging_node_index) != -1:
		_fail("Click-placement drag state did not clear on release.")
	print("SCYTHE_DROP_THEN_DRAG_ADJUST_PROBE ok node=%d delta=%.3f" % [node_index, after_pos.distance_to(before_pos)])
	quit()
