extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_limb(main) -> int:
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if not part.is_empty():
			return i
	return -1


func _build_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = [
		main._topology_component_node(0, "CORE", Vector2(0.40, 0.5), "muscle", _first_torso(main)),
		main._topology_component_node(1, "TEST LIMB", Vector2(0.70, 0.5), "limb_muscle", _first_limb(main)),
	]
	unit["blank_canvas"] = false
	unit["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _mouse_button(local_pos: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = local_pos
	return event


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.ui_language = "en"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	main.editor_board_tool = "layout"
	main._update_editor_ui()
	var click_pos := main._topology_position_to_board_local(Vector2(0.70, 0.5))
	main._handle_editor_board_input(_mouse_button(click_pos, true))
	main._handle_editor_board_input(_mouse_button(click_pos, false))
	if main.editor_hover_popup_view == null or not main.editor_hover_popup_view.visible or not main.editor_hover_pinned:
		_fail("Board click on topology node did not open pinned detail.")
	if main.editor_hover_slot_key != "limb_muscle":
		_fail("Board click should open limb detail, got %s." % main.editor_hover_slot_key)
	var before_visible: bool = bool(main.editor_hover_popup_view.visible)
	main._handle_editor_board_input(_mouse_button(Vector2(20.0, 20.0), true))
	if not before_visible or not main.editor_hover_popup_view.visible:
		_fail("Blank click should not close pinned detail implicitly.")
	print("BOARD_CLICK_PART_HOVER_PROBE ok")
	quit()
