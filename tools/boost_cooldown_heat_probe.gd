extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit():
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "BoostHeatProbe",
		"stats": {
			"health": 100,
			"mass": 10.0,
			"thruster_drive_demand": 50.0,
			"thruster_effective_drive_demand": 50.0,
			"thruster_boost_extra_demand": 50.0,
			"thruster_boost_peak_demand": 100.0,
			"thruster_effective_boost_peak_demand": 100.0,
			"engine_drive_chain_ratio": 1.0,
			"engine_boost_chain_ratio": 1.0,
			"move_momentum": 50.0,
			"body_move_speed": 3.0,
			"move_speed": 3.0,
			"thruster_acceleration": 8.0,
			"boost_momentum": 50.0,
			"boost_total_momentum": 100.0,
			"boost_speed": 10.0,
			"boost_duration": 0.25,
			"boost_cooldown": 0.5,
			"boost_heat": 7.0,
			"heat_capacity": 100.0,
			"movement_profile": "omni",
			"boost_angle_degrees": 360.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso"}],
		},
	})
	unit.deploy(0.0, 0.0)
	unit.set_facing_immediate(1)
	return unit


func _init() -> void:
	var unit = _make_unit()
	var heat_before := float(unit.heat)
	if not unit.boost(Vector2.RIGHT, 32.0):
		_fail("Initial boost should succeed.")
	if float(unit.heat) <= heat_before:
		_fail("Successful boost should add configured heat.")
	if unit.boost(Vector2.RIGHT, 32.0):
		_fail("Boost should respect configured cooldown.")
	unit.tick(0.51, 32.0)
	if not unit.boost(Vector2.RIGHT, 32.0):
		_fail("Boost should be available after cooldown.")
	print("BOOST_COOLDOWN_HEAT_PROBE ok heat=%.1f" % float(unit.heat))
	quit()
