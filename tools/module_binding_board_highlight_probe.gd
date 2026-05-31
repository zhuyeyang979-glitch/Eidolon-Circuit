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


func _build_unit(main, module_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
	var unit_bp := _build_unit(main, module_index)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	var highlights: Dictionary = main._editor_binding_highlights_for_board(unit_bp)
	if highlights.is_empty():
		_fail("Pending binding produced no board highlights.")
	var valid_count := 0
	var invalid_count := 0
	var valid_root := -1
	for raw_key in highlights.keys():
		var info: Dictionary = Dictionary(highlights[raw_key])
		if String(info.get("state", "")) == "binding_valid":
			valid_count += 1
			valid_root = int(raw_key)
		elif String(info.get("state", "")) == "binding_invalid":
			invalid_count += 1
	if valid_count <= 0:
		_fail("No blue-green valid binding highlight was generated.")
	if invalid_count <= 0:
		_fail("No red-orange invalid binding highlight was generated.")
	var candidate: Dictionary = main._pending_module_binding_candidate_for_node(unit_bp, valid_root)
	if candidate.is_empty() or not bool(candidate.get("valid", false)):
		_fail("Highlighted valid node did not resolve to a valid candidate.")
	main._complete_pending_module_binding_with_selection(unit_bp, Array(candidate.get("selection", [valid_root])))
	if not bool(main.editor_pending_module_binding.get("target_selected", false)):
		_fail("Clicking highlighted candidate did not enter key selection.")
	print("MODULE_BINDING_BOARD_HIGHLIGHT_PROBE ok valid=%d invalid=%d" % [valid_count, invalid_count])
	quit()
