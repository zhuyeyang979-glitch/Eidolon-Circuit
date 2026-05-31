extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(boost_heat: float = 9.0, boost_heat_relief: float = 0.0):
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "BoostHeatRuntime",
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
			"boost_heat": boost_heat,
			"boost_heat_relief": boost_heat_relief,
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
	unit.boost_cooldown_timer = 0.25
	var heat_before := float(unit.heat)
	if unit.boost(Vector2.RIGHT, 32.0):
		_fail("Cooldown-blocked boost should fail.")
	if absf(float(unit.heat) - heat_before) > 0.001:
		_fail("Failed boost should not add heat.")
	unit.boost_cooldown_timer = 0.0
	if not unit.boost(Vector2.RIGHT, 32.0):
		_fail("Available boost should succeed.")
	if absf(float(unit.heat) - (heat_before + 9.0)) > 0.01:
		_fail("Successful boost should add exactly configured boost_heat.")
	var heat_after_success := float(unit.heat)
	if unit.boost(Vector2.RIGHT, 32.0):
		_fail("Second boost should be blocked by cooldown.")
	if absf(float(unit.heat) - heat_after_success) > 0.001:
		_fail("Cooldown-failed boost should not add heat.")
	print("BOOST_HEAT_RUNTIME_CONSUMPTION_PROBE ok heat=%.1f" % float(unit.heat))
	quit()
