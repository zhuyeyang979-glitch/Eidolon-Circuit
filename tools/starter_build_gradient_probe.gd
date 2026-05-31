extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		var part: Dictionary = main._selected_component("hero", slot, i)
		if bool(predicate.call(part)):
			return i
	return -1


func _build_starter_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool:
		return main._component_is_torso(part) \
			and main._part_slot_volume_rank(part, "muscle") <= 2.0 \
			and main._torso_plugin_capacity_for_part(part) >= 3 \
			and main._torso_software_capacity_for_part(part) >= 1
	)
	var limb_index := _find(main, "limb_muscle", func(part: Dictionary) -> bool:
		return main._part_slot_volume_rank(part, "limb_muscle") <= 2.0 \
			and main._limb_momentum_max_for_part(part, "limb_muscle") > main._limb_momentum_min_for_part(part, "limb_muscle") \
			and String(part.get("joint_drive_kind", main._joint_drive_kind_for_part(part, "limb_muscle"))).find("rigid") < 0
	)
	var engine_index := _find(main, "engine", func(part: Dictionary) -> bool:
		return main._payload_slot_volume_rank("engine", part, {"kind": "engine"}, "engine") <= 2.0 and main._engine_momentum_output_for_part(part) > 0.0
	)
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool:
		return main._payload_slot_volume_rank("booster", part, {"kind": "booster"}, "booster") <= 2.0 and main._thruster_drive_allocation_min_for_part(part) > 0.0
	)
	var cooling_index := _find(main, "cooling", func(part: Dictionary) -> bool:
		return main._payload_slot_volume_rank("cooling", part, {"kind": "cooling"}, "cooling") <= 2.0 and main._cooling_heat_capacity_for_part(part) > 0.0
	)
	var module_index := _find(main, "module", func(part: Dictionary) -> bool:
		return String(part.get("module_action_profile", "")) == "two_link_forward_snap"
	)
	if torso_index < 0 or limb_index < 0 or engine_index < 0 or booster_index < 0 or cooling_index < 0 or module_index < 0:
		_fail("Missing XS/S starter torso, limb, engine, booster, cooling, or two-link module.")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "STARTER", Vector2(0.42, 0.5), torso_index)
	var limb_a: int = main._append_directed_component_node("hero", unit, nodes, edges, torso, "A", "limb_muscle", limb_index, Vector2.RIGHT, [module_index])
	var limb_b: int = main._append_directed_component_node("hero", unit, nodes, edges, limb_a, "B", "limb_muscle", limb_index, Vector2.RIGHT)
	unit["name"] = "Starter Gradient Probe"
	unit["blank_canvas"] = false
	unit["role"] = "hero"
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "booster", "booster": booster_index, "torso_node": torso},
		{"kind": "cooling", "cooling": cooling_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit["module_bindings"] = [{
		"software_slot_index": 3,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"root_index": limb_a,
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso,
	}]
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit := _build_starter_unit(main)
	var note := main._training_blueprint_illegal_note(1, "hero", unit)
	if note != "":
		_fail("Starter gradient build should be legal, got: %s" % note)
	var stats := main._compute_unit_stats(1, "hero", -1, unit)
	if float(stats.get("drive_margin", -9999.0)) < -0.01:
		_fail("Starter gradient build has negative drive margin.")
	if float(stats.get("thermal_margin", -9999.0)) < -0.01:
		_fail("Starter gradient build has negative thermal margin.")
	print("STARTER_BUILD_GRADIENT_PROBE ok drive=%.1f thermal=%.1f" % [float(stats.get("drive_margin", 0.0)), float(stats.get("thermal_margin", 0.0))])
	quit()
