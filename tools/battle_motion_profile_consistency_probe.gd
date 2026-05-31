extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _setup_battle(profile_name: String):
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_training_config(true)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	main._apply_performance_profile(profile_name, false)
	var hero = main.active_units[1]["hero"]
	if hero == null or not is_instance_valid(hero):
		_fail("Could not start training hero for profile %s." % profile_name)
		return null
	hero.mobius_s = 3.0
	hero.mobius_v = 0.2
	hero.ring_pos = 3.0
	hero.lane = 0.2
	hero.velocity = Vector2(1.35, -0.42)
	hero.angular_velocity = 0.45
	main.battle_simulation_accumulator = 0.0
	main.battle_simulation_step_count = 0
	return main


func _run_one_second(profile_name: String, render_fps: float) -> Dictionary:
	var main = _setup_battle(profile_name)
	if main == null:
		return {}
	var hero = main.active_units[1]["hero"]
	for _frame in range(int(round(render_fps))):
		main._tick_battle(1.0 / render_fps)
	var result := {
		"steps": int(main.battle_simulation_step_count),
		"coord": Vector2(hero.mobius_s, hero.mobius_v),
		"velocity": hero.velocity,
		"facing": hero.facing_angle,
	}
	main.queue_free()
	return result


func _angle_distance(a: float, b: float) -> float:
	return absf(wrapf(a - b + PI, 0.0, TAU) - PI)


func _init() -> void:
	var compat := _run_one_second("compat_60", 72.0)
	var balanced := _run_one_second("balanced_4080s", 120.0)
	var ultra := _run_one_second("ultra_4080s", 144.0)
	for label in ["compat", "balanced", "ultra"]:
		var sample: Dictionary = {"compat": compat, "balanced": balanced, "ultra": ultra}.get(label, {})
		if int(sample.get("steps", 0)) != 120:
			_fail("%s profile should execute 120 simulation steps per second, got %d." % [label, int(sample.get("steps", 0))])
			return
	var base_coord: Vector2 = balanced.get("coord", Vector2.ZERO)
	var base_velocity: Vector2 = balanced.get("velocity", Vector2.ZERO)
	var base_facing := float(balanced.get("facing", 0.0))
	for label in ["compat", "ultra"]:
		var sample: Dictionary = {"compat": compat, "ultra": ultra}.get(label, {})
		var coord: Vector2 = sample.get("coord", Vector2.ZERO)
		var velocity: Vector2 = sample.get("velocity", Vector2.ZERO)
		var facing := float(sample.get("facing", 0.0))
		if coord.distance_to(base_coord) > 0.0005:
			_fail("%s profile final coord diverged from 120fps baseline: %s vs %s." % [label, str(coord), str(base_coord)])
			return
		if velocity.distance_to(base_velocity) > 0.0005:
			_fail("%s profile final velocity diverged from 120fps baseline: %s vs %s." % [label, str(velocity), str(base_velocity)])
			return
		if _angle_distance(facing, base_facing) > 0.0005:
			_fail("%s profile final facing diverged from 120fps baseline: %.6f vs %.6f." % [label, facing, base_facing])
			return
	print("BATTLE_MOTION_PROFILE_CONSISTENCY_PROBE ok coord=%s velocity=%s" % [str(base_coord), str(base_velocity)])
	quit(0)
