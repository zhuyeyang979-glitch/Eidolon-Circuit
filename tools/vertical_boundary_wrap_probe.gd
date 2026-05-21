extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const RING_LENGTH := 24.0
const BATTLE_HALF_HEIGHT := 5.0


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Boundary Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"node_index": 0, "part_kind": "torso", "local_a": Vector2(-0.2, 0.0), "local_b": Vector2(0.2, 0.0), "radius": 0.12}],
			"mass": 12.0,
			"body_move_speed": 2.0,
			"thruster_acceleration": 30.0,
			"boost_momentum": 48.0,
		},
	})
	fighter.deploy(RING_LENGTH - 0.06, BATTLE_HALF_HEIGHT - 0.03)
	fighter.velocity = Vector2(1.0, 2.0)
	fighter.tick(0.2, RING_LENGTH)
	if fighter.ring_pos >= RING_LENGTH - 0.001:
		_fail("Ring X did not wrap at right edge: %.4f." % fighter.ring_pos)
		return
	if absf(fighter.lane - BATTLE_HALF_HEIGHT) > 0.001:
		_fail("Lane Y did not clamp at top boundary: %.4f." % fighter.lane)
		return
	fighter.deploy(0.04, -BATTLE_HALF_HEIGHT + 0.03)
	fighter.velocity = Vector2(-1.0, -2.0)
	fighter.tick(0.2, RING_LENGTH)
	if fighter.ring_pos <= 0.001:
		_fail("Ring X did not wrap at left edge: %.4f." % fighter.ring_pos)
		return
	if absf(fighter.lane + BATTLE_HALF_HEIGHT) > 0.001:
		_fail("Lane Y did not clamp at bottom boundary: %.4f." % fighter.lane)
		return
	print("VERTICAL_BOUNDARY_WRAP_PROBE ring=wrap lane=clamp")
	quit()
