extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
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
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["module_bindings"] = [{"software_slot_index": 0, "module_index": module_index, "attack_key": 1, "target_kind": "limb", "target_nodes": [limb_a, limb_b], "target_torso_node": torso, "binding_valid_note": "OK"}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
		return
	var module_part: Dictionary = main._selected_component("hero", "module", module_index)
	if absf(float(module_part.get("startup_ratio", 0.0)) - (1.0 / 3.0)) > 0.01:
		_fail("Two-Link startup ratio must be 1/3.")
		return
	if absf(float(module_part.get("recovery_ratio", 0.0)) - (2.0 / 3.0)) > 0.01:
		_fail("Two-Link recovery ratio must be 2/3.")
		return
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, _build_unit(main, module_index))
	var binding: Dictionary = Dictionary(Array(stats.get("runtime_module_bindings", []))[0])
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Timing", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	var event := fighter.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Two-Link action failed to start.")
		return
	if absf(float(event.get("startup_ratio", 0.0)) - (1.0 / 3.0)) > 0.01:
		_fail("Runtime event did not carry 1/3 startup ratio.")
		return
	print("TWO_LINK_PHASE_TIMING_PROBE startup=%.3f recovery=%.3f" % [float(event["startup_ratio"]), float(event["recovery_ratio"])])
	quit()
