extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			return i
	return -1


func _first_limb(main) -> int:
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if not part.is_empty():
			return i
	return -1


func _mouse_button(position: Vector2, pressed: bool, double_click: bool = false) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.double_click = double_click
	return event


func _build_unit(main) -> Dictionary:
	var torso_index := _first_torso(main)
	var limb_index := _first_limb(main)
	if torso_index < 0 or limb_index < 0:
		_fail("Could not find torso=%d limb=%d." % [torso_index, limb_index])
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	unit["blank_canvas"] = false
	unit["custom_topology"] = {
		"nodes": [
			main._topology_component_node(0, "TEST TORSO", Vector2(0.42, 0.50), "muscle", torso_index),
			main._topology_component_node(1, "TEST LIMB", Vector2(0.72, 0.50), "limb_muscle", limb_index),
		],
		"edges": [],
		"edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION,
	}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.ui_language = "en"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	main.editor_panel_mode = "parts"
	main.editor_board_tool = "layout"
	main._update_editor_ui()
	var torso_local := main._topology_position_to_board_local(Vector2(0.42, 0.50))
	var limb_local := main._topology_position_to_board_local(Vector2(0.72, 0.50))
	main._handle_editor_board_input(_mouse_button(limb_local, true))
	main._handle_editor_board_input(_mouse_button(limb_local, false))
	if main.editor_hover_popup_view == null or not main.editor_hover_popup_view.visible or not main.editor_hover_pinned:
		_fail("Initial limb click did not open a pinned generic part card.")
	if main.editor_hover_slot_key != "limb_muscle":
		_fail("Initial pinned card should be for the limb, got %s." % main.editor_hover_slot_key)
	var torso_global: Vector2 = main.assembly_board_view.get_global_transform() * torso_local
	var handled: bool = main._route_unit_editor_priority_input(_mouse_button(torso_global, true, true))
	if not handled:
		_fail("Torso double-click with an existing pinned card was not consumed.")
	if main.editor_torso_detail_view == null or not main.editor_torso_detail_view.visible:
		_fail("Torso double-click did not open torso detail when a pinned card existed.")
	if main.editor_open_torso_node_index != 0:
		_fail("Torso detail opened wrong node: %d." % main.editor_open_torso_node_index)
	if main.editor_hover_popup_view != null and main.editor_hover_popup_view.visible and main.editor_hover_pinned:
		_fail("Old pinned part card stayed visible after torso double-click.")
	print("TORSO_DETAIL_DOUBLE_CLICK_WITH_PINNED_PART_PROBE ok")
	quit()
