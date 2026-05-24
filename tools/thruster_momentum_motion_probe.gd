extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(name: String, mass: float):
	var unit = FighterScene.new()
	root.add_child(unit)
	unit._ready()
	unit.setup_unit({
		"unit_name": name,
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": mass,
			"thruster_drive_demand": 80.0,
			"thruster_effective_drive_demand": 80.0,
			"thruster_boost_extra_demand": 120.0,
			"thruster_boost_peak_demand": 200.0,
			"thruster_effective_boost_peak_demand": 200.0,
			"engine_drive_chain_ratio": 1.0,
			"engine_boost_chain_ratio": 1.0,
			"move_momentum": 80.0,
			"body_move_speed": 4.0,
			"move_speed": 4.0,
			"thruster_acceleration": 80.0 / mass,
			"boost_momentum": 120.0,
			"boost_total_momentum": 200.0,
			"boost_speed": 200.0 / mass,
			"boost_duration": 0.24,
			"turn_speed": 1.0,
			"turn_acceleration": 1.0,
			"turn_damping": 1.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"node_index": 0, "part_kind": "torso"}],
		},
	})
	unit.deploy(1.0, 0.0)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var light_stats := {"mass": 12.0, "speed_mult": 1.0, "thruster_drive_demand": 80.0, "thruster_allocated_momentum": 9999.0, "thruster_boost_extra_demand": 160.0, "thruster_boost_peak_demand": 240.0, "engine_momentum_output": 240.0, "move_efficiency": 1.0, "boost_efficiency": 1.0, "boost_momentum": 160.0, "boost_duration": 0.3, "brake_efficiency": 1.0, "speed": 1.0}
	var heavy_stats := light_stats.duplicate(true)
	heavy_stats["mass"] = 48.0
	main._apply_engine_momentum_budget(light_stats, "hero")
	main._apply_thruster_momentum_stats(light_stats, "hero")
	main._apply_engine_momentum_budget(heavy_stats, "hero")
	main._apply_thruster_momentum_stats(heavy_stats, "hero")
	if float(light_stats.get("thruster_acceleration", 0.0)) <= float(heavy_stats.get("thruster_acceleration", 0.0)):
		_fail("Same thruster should accelerate the lighter mech faster.")
	if float(light_stats.get("boost_speed", 0.0)) <= float(heavy_stats.get("boost_speed", 0.0)):
		_fail("Same boost momentum should produce higher boost speed on lighter mech.")
	var light = _make_unit("LIGHT", 12.0)
	var heavy = _make_unit("HEAVY", 48.0)
	light.move_by(Vector2.RIGHT, 0.25, 24.0)
	heavy.move_by(Vector2.RIGHT, 0.25, 24.0)
	if light.velocity.length() <= heavy.velocity.length() * 2.5:
		_fail("Movement acceleration should be mass sensitive.")
	var preserved: Vector2 = light.velocity
	light.tick(0.5, 24.0)
	if light.velocity.distance_to(preserved) > 0.01:
		_fail("Velocity should be preserved without input or external force in space.")
	print("THRUSTER_MOMENTUM_MOTION_PROBE light_acc=%.3f heavy_acc=%.3f preserved=%.3f" % [
		float(light_stats["thruster_acceleration"]),
		float(heavy_stats["thruster_acceleration"]),
		light.velocity.length(),
	])
	quit()
