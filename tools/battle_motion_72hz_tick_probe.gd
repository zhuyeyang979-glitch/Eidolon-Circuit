extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._apply_performance_profile("compat_60", false)
	if int(round(MainScene.BATTLE_SIMULATION_FPS)) != 72:
		_fail("Battle simulation FPS should be 72, got %.2f." % MainScene.BATTLE_SIMULATION_FPS)
		return
	if Engine.max_fps < 72 or Engine.physics_ticks_per_second < 72:
		_fail("Runtime frame/tick caps should both be at least 72, got fps=%d physics=%d." % [Engine.max_fps, Engine.physics_ticks_per_second])
		return
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "72Hz Motion",
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
			"recoil_stabilization": 1.0,
		},
	})
	fighter.deploy(4.0, 0.0)
	fighter._ensure_limb_index(0)
	fighter.limb_swing_angles[0] = 0.42
	fighter.limb_swing_velocities[0] = -0.2
	fighter.limb_linear_offsets[0] = Vector2(0.14, 0.0)
	fighter.limb_linear_velocities[0] = Vector2(-0.08, 0.0)
	var previous_pos := Vector2(fighter.ring_pos, fighter.lane)
	var previous_angle: float = fighter.facing_angle
	var previous_limb_angle := float(fighter.limb_swing_angles[0])
	var max_move_step := 0.0
	var max_turn_step := 0.0
	var max_limb_step := 0.0
	for i in range(72):
		fighter.request_turn(1, MainScene.BATTLE_FRAME_DELTA)
		fighter.move_by(Vector2.RIGHT, MainScene.BATTLE_FRAME_DELTA, MainScene.RING_LENGTH)
		fighter.tick(MainScene.BATTLE_FRAME_DELTA, MainScene.RING_LENGTH)
		var next_pos := Vector2(fighter.ring_pos, fighter.lane)
		max_move_step = maxf(max_move_step, next_pos.distance_to(previous_pos))
		max_turn_step = maxf(max_turn_step, absf(wrapf(fighter.facing_angle - previous_angle, -PI, PI)))
		max_limb_step = maxf(max_limb_step, absf(float(fighter.limb_swing_angles[0]) - previous_limb_angle))
		previous_pos = next_pos
		previous_angle = fighter.facing_angle
		previous_limb_angle = float(fighter.limb_swing_angles[0])
	var total_delta := Vector2(fighter.ring_pos, fighter.lane) - Vector2(4.0, 0.0)
	if total_delta.length() <= 1.0:
		_fail("72Hz movement did not advance enough over one second: %.3f." % total_delta.length())
		return
	if max_move_step > 0.052:
		_fail("72Hz movement frame step is too chunky: %.4f." % max_move_step)
		return
	if max_turn_step > 0.09:
		_fail("72Hz turn frame step is too chunky: %.4f." % max_turn_step)
		return
	if max_limb_step > 0.06:
		_fail("72Hz limb frame step is too chunky: %.4f." % max_limb_step)
		return
	print("BATTLE_MOTION_72HZ_TICK_PROBE ok move_step=%.4f turn_step=%.4f limb_step=%.4f total=%.3f" % [
		max_move_step,
		max_turn_step,
		max_limb_step,
		total_delta.length(),
	])
	quit(0)
