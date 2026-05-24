extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		if bool(predicate.call(main._selected_component("hero", slot, i))):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var part := {
		"name": "Probe Fixed Thruster",
		"thruster_family": "cruise_blue",
		"momentum_min": 20.0,
		"allocated_momentum": 999.0,
		"boost_momentum": 30.0,
		"move_efficiency": 1.5,
		"boost_efficiency": 2.0,
		"thruster_idle_heat_coeff": 0.25,
	}
	if absf(main._thruster_drive_demand_for_part(part) - 20.0) > 0.001:
		_fail("Thruster fixed drive demand should use momentum_min before allocated_momentum.")
	if absf(main._booster_normal_momentum_for_part(part) - 30.0) > 0.001:
		_fail("Normal thruster move momentum should derive from fixed demand.")
	if absf(main._thruster_boost_total_momentum_for_part(part) - 100.0) > 0.001:
		_fail("Total boost should derive from fixed demand + boost extra.")
	if absf(main._booster_idle_heat_for_part(part) - 5.0) > 0.001:
		_fail("Idle heat should derive from fixed demand.")

	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(candidate: Dictionary) -> bool: return main._component_is_torso(candidate))
	var engine_index := _find(main, "engine", func(candidate: Dictionary) -> bool: return main._engine_momentum_output_for_part(candidate) > 0.0)
	var booster_index := _find(main, "booster", func(candidate: Dictionary) -> bool: return main._thruster_drive_demand_for_part(candidate) > 0.0)
	if torso_index < 0 or engine_index < 0 or booster_index < 0:
		_fail("Probe could not find torso, engine, and booster parts.")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	unit["blank_canvas"] = false
	unit["role"] = "hero"
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "booster", "booster": booster_index, "torso_node": torso, "allocated_momentum": 9999.0},
	]
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var booster_part: Dictionary = main._selected_component("hero", "booster", booster_index)
	var expected := main._thruster_drive_demand_for_part(booster_part)
	var expected_boost_brake := main._thruster_boost_brake_allocation_min_for_part(booster_part)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit)
	if absf(float(stats.get("thruster_drive_demand", -1.0)) - expected) > 0.01:
		_fail("Old booster payload allocated_momentum changed thruster_drive_demand.")
	if absf(float(stats.get("thruster_allocated_momentum", -1.0)) - expected) > 0.01:
		_fail("Compatibility thruster_allocated_momentum should mirror fixed demand.")
	if absf(float(stats.get("engine_momentum_required", -1.0)) - (expected + expected_boost_brake)) > 0.01:
		_fail("Engine demand should use fixed drive plus boost/brake demand when no limbs are bound.")
	print("THRUSTER_FIXED_DRIVE_DEMAND_PROBE ok demand=%.1f required=%.1f" % [expected, float(stats.get("engine_momentum_required", 0.0))])
	quit()
