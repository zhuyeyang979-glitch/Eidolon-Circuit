extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const RING_LENGTH := 24.0


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_fighter():
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Eight Direction Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"node_index": 0, "part_kind": "torso", "local_a": Vector2(-0.2, 0.0), "local_b": Vector2(0.2, 0.0), "radius": 0.12}],
			"mass": 12.0,
			"body_move_speed": 2.0,
			"thruster_acceleration": 30.0,
			"boost_momentum": 48.0,
			"boost_duration": 0.3,
			"thruster_cone_degrees": 20.0,
		},
	})
	fighter.deploy(8.0, 0.0)
	return fighter


func _init() -> void:
	var directions := [
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.UP,
		Vector2.DOWN,
		(Vector2.RIGHT + Vector2.UP).normalized(),
		(Vector2.RIGHT + Vector2.DOWN).normalized(),
		(Vector2.LEFT + Vector2.UP).normalized(),
		(Vector2.LEFT + Vector2.DOWN).normalized(),
	]
	for direction in directions:
		var fighter = _make_fighter()
		fighter.facing_angle = direction.angle()
		var before := Vector2(fighter.ring_pos, fighter.lane)
		fighter.move_by(direction, 0.25, RING_LENGTH)
		fighter.tick(0.25, RING_LENGTH)
		var after := Vector2(fighter.ring_pos, fighter.lane)
		var delta := after - before
		if direction.x != 0.0 and absf(delta.x) <= 0.001:
			_fail("Runtime movement lost X component for direction %s." % [str(direction)])
			return
		if direction.y != 0.0 and absf(delta.y) <= 0.001:
			_fail("Runtime movement lost Y component for direction %s." % [str(direction)])
			return
		if direction.dot(delta.normalized() if delta.length() > 0.001 else Vector2.ZERO) < 0.58:
			_fail("Runtime movement direction was clipped by thruster cone: requested=%s delta=%s." % [str(direction), str(delta)])
			return
	print("EIGHT_DIRECTION_RUNTIME_MOVEMENT_PROBE directions=%d" % directions.size())
	quit()
