extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _unit(profile: String, runtime_topology: bool):
	var unit = FighterScene.new()
	root.add_child(unit)
	var stats := {
		"health": 100,
		"mass": 12.0,
		"move_speed": 4.0,
		"body_move_speed": 4.0,
		"move_acceleration": 24.0,
		"thruster_acceleration": 24.0,
		"movement_profile": profile,
		"boost_angle_degrees": 70.0,
		"teamedit_runtime_topology": runtime_topology,
	}
	if runtime_topology:
		stats["runtime_topology_segments"] = [{"part_kind": "torso", "a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}]
	unit.setup_unit({"owner_id": 1, "role": "hero", "unit_name": "%s_%s" % [profile, str(runtime_topology)], "stats": stats})
	unit.deploy(4.0, 0.0)
	return unit


func _assert_vertical(profile: String, runtime_topology: bool, dir: Vector2) -> void:
	var unit = _unit(profile, runtime_topology)
	unit.move_by(dir, 0.18, MainScene.RING_LENGTH)
	if absf(unit.velocity.y) <= 0.001:
		_fail("%s runtime=%s should get vertical velocity from %s." % [profile, str(runtime_topology), str(dir)])
		return
	unit.tick(0.18, MainScene.RING_LENGTH)
	if absf(unit.mobius_v) <= 0.001 or absf(unit.lane) <= 0.001:
		_fail("%s runtime=%s should advance lane/mobius_v from %s." % [profile, str(runtime_topology), str(dir)])
		return
	if signf(unit.velocity.y) != signf(dir.y):
		_fail("%s runtime=%s vertical velocity sign mismatch for %s." % [profile, str(runtime_topology), str(dir)])


func _init() -> void:
	for profile in ["omni", "car", "vector"]:
		for runtime_topology in [true, false]:
			_assert_vertical(profile, runtime_topology, Vector2.UP)
			_assert_vertical(profile, runtime_topology, Vector2.DOWN)
	print("BATTLE_VERTICAL_MOVEMENT_ALL_PROFILES_PROBE ok")
	quit()
