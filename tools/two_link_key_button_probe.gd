extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _module_index(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _build_unit(main, module_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "software_slot_index": 0}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _module_index(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
		quit(1)
		return
	var unit_bp := _build_unit(main, module_index)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_canvas_mode = "blank"
	main.editor_pending_module_binding = {"payload_index": 0, "module_index": module_index, "attack_key": 0, "target_selected": false}
	main._refresh_editor_module_binding_buttons()
	if bool(main.editor_action_buttons["bind_key_1"].visible):
		_fail("Key buttons should be hidden until a target is selected.")
	main._complete_pending_module_binding_with_selection(unit_bp, [2])
	main._refresh_editor_module_binding_buttons()
	if not bool(main.editor_action_buttons["bind_key_6"].visible):
		_fail("Key buttons should be visible after target selection.")
	if String(main.editor_action_buttons["bind_key_6"].text) != "6 L":
		_fail("Key 6 button should display keyboard L.")
	main._editor_action("bind_key_6")
	var bindings: Array = unit_bp.get("module_bindings", [])
	if bindings.size() != 1 or int(Dictionary(bindings[0]).get("attack_key", 0)) != 6:
		_fail("Clicking bind_key_6 did not write attack key 6.")
	if not main.editor_pending_module_binding.is_empty():
		_fail("Pending binding should clear after key button completion.")
	if failed:
		quit(1)
		return
	print("TWO_LINK_KEY_BUTTON_PROBE ok")
	quit()
