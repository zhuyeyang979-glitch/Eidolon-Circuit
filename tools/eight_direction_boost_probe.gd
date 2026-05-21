extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_fighter():
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "EIGHT_BOOST",
		"stats": {
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso", "node_index": 0, "a_local": Vector2(-0.2, 0.0), "b_local": Vector2(0.2, 0.0), "radius": 0.08}],
			"mass": 10.0,
			"body_move_speed": 4.0,
			"thruster_acceleration": 4.0,
			"thruster_momentum": 40.0,
			"boost_momentum": 80.0,
			"boost_duration": 0.5,
			"turn_speed": 2.0,
			"thruster_cone_degrees": 180.0,
		},
	})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var fighter = _make_fighter()
	if not fighter.boost(Vector2(1.0, -1.0), 24.0):
		_fail("Diagonal boost call failed.")
		return
	fighter._tick_boost_drive(0.5)
	if fighter.velocity.length() <= 0.01:
		_fail("Diagonal boost produced no velocity.")
		return
	var direction: Vector2 = fighter.velocity.normalized()
	if direction.distance_to(Vector2(1.0, -1.0).normalized()) > 0.02:
		_fail("Boost direction was not the normalized eight-way input.")
		return
	print("EIGHT_DIRECTION_BOOST_PROBE velocity=%s" % fighter.velocity)
	quit()
