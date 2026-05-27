extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "120Hz Motion",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_kind": "torso", "local_a": Vector2(-0.22, 0.0), "local_b": Vector2(0.22, 0.0), "radius": 0.12, "mass": 8.0},
				{"node_index": 1, "part_kind": "limb_muscle", "local_a": Vector2(0.18, 0.0), "local_b": Vector2(0.74, 0.0), "radius": 0.055, "mass": 4.0},
			],
			"mass": 12.0,
			"move_speed": 3.0,
			"move_acceleration": 80.0,
			"speedometer_max_speed": 12.0,
			"turn_speed": 4.2,
			"turn_acceleration": 7.8,
			"turn_damping": 4.8,
		},
	})
	fighter.deploy(4.0, 0.0)
	fighter._ensure_limb_index(0)
	fighter.limb_swing_angles[0] = 0.42
	fighter.limb_swing_velocities[0] = -0.2
	var previous_pos := Vector2(fighter.ring_pos, fighter.lane)
	var previous_angle: float = fighter.facing_angle
	var max_move_step := 0.0
	var max_turn_step := 0.0
	for _step in range(120):
		fighter.request_turn(1, MainScene.BATTLE_SIMULATION_DELTA)
		fighter.move_by_gameplay(Vector2.RIGHT, MainScene.BATTLE_SIMULATION_DELTA, MainScene.RING_LENGTH)
		fighter.tick(MainScene.BATTLE_SIMULATION_DELTA, MainScene.RING_LENGTH)
		var next_pos := Vector2(fighter.ring_pos, fighter.lane)
		max_move_step = maxf(max_move_step, next_pos.distance_to(previous_pos))
		max_turn_step = maxf(max_turn_step, absf(wrapf(fighter.facing_angle - previous_angle + PI, 0.0, TAU) - PI))
		previous_pos = next_pos
		previous_angle = fighter.facing_angle
	if max_move_step > 0.032 or max_turn_step > 0.055:
		_fail("120Hz motion remains visibly stepped: move=%.4f turn=%.4f." % [max_move_step, max_turn_step])
		return
	print("BATTLE_MOTION_120HZ_TICK_PROBE ok move_step=%.4f turn_step=%.4f" % [max_move_step, max_turn_step])
	quit(0)
