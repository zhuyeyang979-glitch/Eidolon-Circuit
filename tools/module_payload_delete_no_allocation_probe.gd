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


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = torso
	main._refresh_torso_detail_view()
	var view = main.editor_torso_detail_view
	var allocation_count := [0]
	view.engine_allocation_requested.connect(func(_payload_index: int): allocation_count[0] = int(allocation_count[0]) + 1)
	var slot_index := -1
	for i in range(view.software_entries.size()):
		if view.software_entries[i] is Dictionary and int(Dictionary(view.software_entries[i]).get("payload_index", -1)) == 0:
			slot_index = i
			break
	if slot_index < 0:
		_fail("Module payload is not visible in software slots.")
	var delete_pos: Vector2 = view._remove_rect_for_slot(view._slot_rect("software", slot_index)).get_center()
	var hit: Dictionary = view._slot_hit(delete_pos)
	if String(hit.get("action", "")) != "delete":
		_fail("Module delete hot zone did not resolve to delete action.")
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = delete_pos
	view._gui_input(event)
	if int(allocation_count[0]) != 0:
		_fail("Module delete click incorrectly emitted engine allocation request.")
	if not Array(unit_bp.get("slot_payloads", [])).is_empty():
		_fail("Module delete click did not delete the payload.")
	print("MODULE_PAYLOAD_DELETE_NO_ALLOCATION_PROBE ok")
	quit()
