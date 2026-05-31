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
	var torso_index := _first_torso(main)
	var limb_index := _first_limb(main)
	if torso_index < 0 or limb_index < 0:
		return {}
	var nodes: Array = []
	var edges: Array = []
	var root_index: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.50), torso_index)
	main._append_directed_component_node("hero", unit, nodes, edges, root_index, "TEST LIMB", "limb_muscle", limb_index, Vector2.RIGHT)
	unit["blank_canvas"] = false
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _mouse_button(global_pos: Vector2, pressed: bool, button_index: int = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = pressed
	event.position = global_pos
	event.global_position = global_pos
	return event


func _edge_count(main) -> int:
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	return Array(topology.get("edges", [])).size()


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.ui_language = "en"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	if main.editor_working_blueprint.is_empty():
		_fail("Could not build connected test unit.")
		return
	main._update_editor_ui()
	var before_edges := _edge_count(main)
	if before_edges <= 0:
		_fail("Connected test unit has no edge to protect.")
		return
	main._show_editor_topology_node_detail(1, "board", {"position": Vector2(520.0, 86.0)})
	if main.editor_hover_popup_view == null or not main.editor_hover_popup_view.visible or not main.editor_hover_pinned:
		_fail("Board part detail did not open.")
		return
	var board_pos: Vector2 = main.assembly_board_view.get_global_rect().position + main._topology_position_to_board_local(Vector2(0.53, 0.50))
	var handled := main._route_unit_editor_priority_input(_mouse_button(board_pos, true, MOUSE_BUTTON_RIGHT))
	if not handled:
		_fail("Right click was not consumed by pinned part detail close.")
		return
	if main.editor_hover_popup_view.visible:
		_fail("Right click did not close pinned part detail.")
		return
	if _edge_count(main) != before_edges:
		_fail("Right click close also unlinked a topology edge.")
		return
	if main.editor_node_click_candidate_index != -1:
		_fail("Right click close did not clear board click candidate.")
		return
	print("EDITOR_PART_DETAIL_RIGHT_CLICK_CLOSE_NO_UNLINK_PROBE ok edges=%d" % before_edges)
	quit()
