extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


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


func _software_entries(main, unit_bp: Dictionary) -> Array:
	return main._torso_software_slot_summary(unit_bp, 0)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
		quit(1)
		return
	var unit_bp := _build_unit(main, module_index)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_canvas_mode = "blank"
	main.editor_open_torso_node_index = 0
	main.editor_pending_module_binding = {"payload_index": 0, "module_index": module_index, "attack_key": 0, "target_selected": false}
	main._complete_pending_module_binding_with_selection(unit_bp, [1])
	main._set_pending_module_attack_key(1)
	var entries := _software_entries(main, unit_bp)
	if entries.is_empty() or not String(Dictionary(entries[0]).get("line", "")).contains("1U"):
		_fail("Torso detail did not show bound key 1U: %s" % (str(entries) if not entries.is_empty() else "empty"))
	if not bool(Dictionary(entries[0]).get("can_rebind", false)):
		_fail("Bound action module did not expose rebind action.")
	main._rebind_torso_payload_at(0)
	if main.editor_pending_module_binding.is_empty():
		_fail("Rebind did not enter pending binding mode.")
	if Array(unit_bp.get("module_bindings", [])).size() != 0:
		_fail("Rebind did not clear old binding.")
	main._complete_pending_module_binding_with_selection(unit_bp, [1])
	main._set_pending_module_attack_key(2)
	var rebound_entries := _software_entries(main, unit_bp)
	if rebound_entries.is_empty() or not String(Dictionary(rebound_entries[0]).get("line", "")).contains("2I"):
		_fail("Torso detail did not show rebound key 2I.")
	if failed:
		quit(1)
		return
	print("MODULE_BINDING_DETAIL_REBIND_PROBE ok")
	quit()
