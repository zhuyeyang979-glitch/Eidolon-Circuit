extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		if bool(predicate.call(Dictionary(main._catalog_for("hero", slot)[i]))):
			return i
	return -1


func _build_unit(main, engine_index: int, booster_index: int) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var booster_part: Dictionary = main._selected_component("hero", "booster", booster_index)
	var nodes: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	unit["blank_canvas"] = false
	unit["role"] = "hero"
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{
			"kind": "booster",
			"booster": booster_index,
			"torso_node": torso,
			"thruster_drive_allocated_momentum": main._thruster_drive_allocation_max_for_part(booster_part),
			"thruster_boost_brake_allocated_momentum": main._thruster_boost_brake_allocation_max_for_part(booster_part),
		},
	]
	unit["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var engine_index := _find(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 0.0)
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_drive_allocation_min_for_part(part) > 0.0)
	if engine_index < 0 or booster_index < 0:
		_fail("Missing engine or booster.")
	var unit := _build_unit(main, engine_index, booster_index)
	var stats: Dictionary = main._compute_unit_stats(0, "hero", 0, unit)
	var drive := float(stats.get("thruster_drive_demand", 0.0))
	var boost := float(stats.get("thruster_boost_extra_demand", 0.0))
	var required := float(stats.get("engine_momentum_required", 0.0))
	if drive <= 0.0:
		_fail("Expected drive allocation in stats.")
	if absf(required - (drive + boost)) > 0.05:
		_fail("Engine required should include drive + boost/brake for no-limb unit: required %.3f drive %.3f boost %.3f" % [required, drive, boost])
	print("THRUSTER_DUAL_BUDGET_LEGALITY_PROBE ok required=%.1f drive=%.1f boost=%.1f" % [required, drive, boost])
	quit()
