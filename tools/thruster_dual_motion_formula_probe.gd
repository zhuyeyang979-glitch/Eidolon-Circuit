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


func _unit(main, engine_index: int, booster_index: int, drive: float, boost: float) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var nodes: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	unit["blank_canvas"] = false
	unit["role"] = "hero"
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "booster", "booster": booster_index, "torso_node": torso, "thruster_drive_allocated_momentum": drive, "thruster_boost_brake_allocated_momentum": boost},
	]
	unit["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var engine_index := _find(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 250.0)
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_boost_brake_allocation_max_for_part(part) > main._thruster_boost_brake_allocation_min_for_part(part))
	if engine_index < 0 or booster_index < 0:
		_fail("Missing strong engine or boost-capable booster.")
	var booster_part: Dictionary = main._selected_component("hero", "booster", booster_index)
	var drive_min := main._thruster_drive_allocation_min_for_part(booster_part)
	var drive_max := main._thruster_drive_allocation_max_for_part(booster_part)
	var boost_min := main._thruster_boost_brake_allocation_min_for_part(booster_part)
	var boost_max := main._thruster_boost_brake_allocation_max_for_part(booster_part)
	var low: Dictionary = main._compute_unit_stats(0, "hero", 0, _unit(main, engine_index, booster_index, drive_min, boost_min))
	var boost_only: Dictionary = main._compute_unit_stats(0, "hero", 0, _unit(main, engine_index, booster_index, drive_min, boost_max))
	var drive_high: Dictionary = main._compute_unit_stats(0, "hero", 0, _unit(main, engine_index, booster_index, drive_max, boost_min))
	if absf(float(low.get("move_speed", 0.0)) - float(boost_only.get("move_speed", 0.0))) > 0.02:
		_fail("Move speed changed when only boost/brake allocation changed.")
	if float(drive_high.get("move_speed", 0.0)) <= float(low.get("move_speed", 0.0)):
		_fail("Move speed did not increase with drive allocation.")
	if float(boost_only.get("boost_speed", 0.0)) <= float(low.get("boost_speed", 0.0)):
		_fail("Boost speed did not increase with boost/brake allocation.")
	if float(boost_only.get("brake_power", 0.0)) <= float(low.get("brake_power", 0.0)):
		_fail("Brake power did not increase with boost/brake allocation.")
	print("THRUSTER_DUAL_MOTION_FORMULA_PROBE ok move %.2f->%.2f boost %.2f->%.2f brake %.2f->%.2f" % [
		float(low.get("move_speed", 0.0)),
		float(drive_high.get("move_speed", 0.0)),
		float(low.get("boost_speed", 0.0)),
		float(boost_only.get("boost_speed", 0.0)),
		float(low.get("brake_power", 0.0)),
		float(boost_only.get("brake_power", 0.0)),
	])
	quit()
