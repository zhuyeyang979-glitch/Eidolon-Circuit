extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _node_count(main) -> int:
	var unit_bp: Dictionary = main._editor_current_blueprint()
	return Array(Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])).size()


func _mouse_button(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	return event


func _mouse_motion(position: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	return event


func _first_catalog_button(main):
	for button in main.editor_catalog_buttons:
		if button is Button and button.visible and not button.disabled:
			if button.has_method("set_card") and String(button.slot_key) in ["limb_muscle", "muscle"]:
				return button
	return null


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main._select_editor_part_group("muscle")
	main._select_editor_part_filter(5)
	var button = _first_catalog_button(main)
	if button == null:
		_fail("No visible physical catalog card button found.")
	var start: Vector2 = button.get_global_rect().get_center()
	if main.editor_drag_ghost_view == null:
		_fail("Editor drag ghost view was not created.")
	if main.editor_drag_ghost_view.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("Drag ghost must ignore mouse input.")
	main._handle_editor_catalog_manual_drag(_mouse_button(start, true))
	if main.editor_drag_ghost_view.visible:
		_fail("Drag ghost should stay hidden until movement crosses threshold.")
	var drag_pos := start + Vector2(-130.0, 44.0)
	main._handle_editor_catalog_manual_drag(_mouse_motion(drag_pos))
	if not main.editor_drag_ghost_view.visible:
		_fail("Drag ghost did not become visible after manual drag threshold.")
	if absf(main.editor_drag_ghost_view.modulate.a - 0.55) > 0.02:
		_fail("Drag ghost alpha should be about 0.55, got %.2f." % main.editor_drag_ghost_view.modulate.a)
	var expected_position: Vector2 = drag_pos - main.editor_drag_ghost_view.size * 0.5
	if main.editor_drag_ghost_view.position.distance_to(expected_position) > 1.5:
		_fail("Drag ghost did not follow mouse center; drift %.2f." % main.editor_drag_ghost_view.position.distance_to(expected_position))
	var before_outside := _node_count(main)
	main._handle_editor_catalog_manual_drag(_mouse_button(Vector2(20.0, 20.0), false))
	if main.editor_drag_ghost_view.visible:
		_fail("Drag ghost remained visible after releasing outside board.")
	if _node_count(main) != before_outside:
		_fail("Dropping outside board changed node count.")
	main._handle_editor_catalog_manual_drag(_mouse_button(start, true))
	var board_center: Vector2 = main.assembly_board_view.get_global_rect().get_center()
	main._handle_editor_catalog_manual_drag(_mouse_motion(board_center))
	if not main.editor_drag_ghost_view.visible:
		_fail("Drag ghost did not show during second drag.")
	main._drop_catalog_part_on_board(String(button.slot_key), int(button.part_index), main.assembly_board_view.size * 0.5)
	main._clear_editor_catalog_manual_drag()
	if main.editor_drag_ghost_view.visible:
		_fail("Drag ghost remained visible after successful drop cleanup.")
	if _node_count(main) <= before_outside:
		_fail("Dropping inside board did not add a topology node.")
	print("EDITOR_DRAG_PREVIEW_PROBE ghost_size=%s nodes=%d alpha=%.2f" % [str(main.editor_drag_ghost_view.size), _node_count(main), main.editor_drag_ghost_view.modulate.a])
	quit()
