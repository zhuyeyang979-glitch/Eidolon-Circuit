extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _best_engine(main) -> int:
	var best := -1
	var best_output := -1.0
	for i in range(main._catalog_for("hero", "engine").size()):
		var part: Dictionary = Dictionary(main._catalog_for("hero", "engine")[i])
		var output: float = main._engine_momentum_output_for_part(part)
		if output > best_output:
			best_output = output
			best = i
	return best


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		var part: Dictionary = Dictionary(main._catalog_for("hero", slot)[i])
		if bool(predicate.call(part)):
			return i
	return -1


func _build_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_drive_allocation_max_for_part(part) > 0.0)
	var engine_index := _best_engine(main)
	var module_index := _find(main, "module", func(part: Dictionary) -> bool: return String(part.get("module_action_profile", "")) == "two_link_forward_snap")
	if torso_index < 0 or booster_index < 0 or engine_index < 0 or module_index < 0:
		_fail("Missing fixture parts.")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	var limb_a: int = main._append_directed_component_node("hero", unit, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT, [module_index])
	unit["blank_canvas"] = false
	unit["role"] = "hero"
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "booster", "booster": booster_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit["module_bindings"] = [{
		"software_slot_index": 2,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"root_index": limb_a,
		"target_nodes": [limb_a],
		"target_torso_node": torso,
	}]
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _adjustable_total(data: Dictionary, field: String) -> float:
	var total := 0.0
	for raw_entry in Array(data.get("entries", [])):
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		if ["booster_drive", "booster_boost_brake", "limb"].has(String(entry.get("kind", ""))):
			total += maxf(0.0, float(entry.get(field, 0.0)))
	return total


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	main._open_engine_momentum_allocation_for_payload(0)
	var before := main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var pool := float(before.get("engine_output", 0.0))
	var max_total := _adjustable_total(before, "max_momentum")
	if pool <= max_total + 0.5:
		_fail("Fixture needs engine surplus: pool %.1f max %.1f" % [pool, max_total])
	main._equalize_engine_momentum_allocation()
	var after := main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var used := _adjustable_total(after, "momentum")
	var used_ratio := float(after.get("used_ratio", 0.0))
	if absf(used - max_total) > 0.2:
		_fail("Surplus equalize should clamp entries at max: used %.2f max %.2f" % [used, max_total])
	if used_ratio >= 0.999:
		_fail("Surplus should remain in pool, used_ratio %.3f" % used_ratio)
	print("POWER_ALLOCATION_EQUALIZE_SURPLUS_PROBE ok pool=%.1f used=%.1f remaining=%.1f" % [pool, used, pool - used])
	quit()
