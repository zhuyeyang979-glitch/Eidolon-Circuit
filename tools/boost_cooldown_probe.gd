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
		"unit_name": "BoostCooldownProbe",
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
			"thruster_acceleration": 10.0,
			"boost_momentum": 50.0,
			"boost_total_momentum": 100.0,
			"boost_speed": 10.0,
			"boost_duration": 0.3,
			"boost_cooldown": 0.5,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso"}],
		},
	})
	unit.deploy(0.0, 0.0)
	unit.set_facing_immediate(1)
	return unit


func _init() -> void:
	var unit = _make_unit()
	if not unit.boost(Vector2.RIGHT, 24.0):
		_fail("First boost should succeed.")
		return
	if unit.boost(Vector2.RIGHT, 24.0):
		_fail("Second boost during cooldown should fail.")
		return
	unit.tick(0.49, 24.0)
	if unit.boost(Vector2.RIGHT, 24.0):
		_fail("Boost should still be cooling down at 0.49s.")
		return
	unit.tick(0.02, 24.0)
	if not unit.boost(Vector2.RIGHT, 24.0):
		_fail("Boost should succeed after 0.5s cooldown.")
		return
	print("BOOST_COOLDOWN_PROBE ok")
	quit()
