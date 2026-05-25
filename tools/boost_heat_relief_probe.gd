extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(relief: float):
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "BoostHeatRelief",
		"stats": {
			"health": 100,
			"mass": 10.0,
			"move_speed": 3.0,
			"move_acceleration": 12.0,
			"move_momentum": 30.0,
			"boost_momentum": 120.0,
			"boost_total_momentum": 120.0,
			"boost_speed": 12.0,
			"boost_duration": 0.2,
			"boost_cooldown": 0.4,
			"thruster_boost_extra_demand": 30.0,
			"boost_heat": 20.0,
			"boost_heat_relief": relief,
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
	var plain = _make_unit(0.0)
	var relieved = _make_unit(0.25)
	if not plain.boost(Vector2.RIGHT, 32.0):
		_fail("Plain boost should succeed.")
	if not relieved.boost(Vector2.RIGHT, 32.0):
		_fail("Relieved boost should succeed.")
	if absf(float(plain.heat) - 20.0) > 0.01:
		_fail("Plain boost heat should be 20.")
	if absf(float(relieved.heat) - 15.0) > 0.01:
		_fail("boost_heat_relief should reduce boost heat by 25%.")
	print("BOOST_HEAT_RELIEF_PROBE ok plain=%.1f relieved=%.1f" % [float(plain.heat), float(relieved.heat)])
	quit()
