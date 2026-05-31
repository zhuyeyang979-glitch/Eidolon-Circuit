extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _surface_config() -> Dictionary:
	var config := MobiusWorld.default_config(
		MainScene.RING_LENGTH,
		MainScene.BATTLE_HALF_HEIGHT * 2.0,
		MainScene.VIEW_WIDTH,
		MainScene.VIEW_HEIGHT,
		Rect2(Vector2(MainScene.ARENA_LEFT, MainScene.ARENA_TOP), Vector2(MainScene.ARENA_WIDTH, MainScene.ARENA_HEIGHT))
	)
	config["screen_scale"] = MainScene.ARENA_HEIGHT / MainScene.VIEW_HEIGHT
	config["local_rectangular_projection"] = false
	config["twist_visual_enabled"] = true
	config["rotation_interval_min"] = 0.10
	config["rotation_interval_max"] = 0.12
	config["rotation_blend_seconds"] = 0.08
	config["twist_wave_speed"] = 0.16
	config["twist_wave_amplitude"] = 0.24
	config["twist_wave_scale"] = 1.35
	config["twist_pivot_influence"] = 0.42
	return config


func _init() -> void:
	seed(0x510A1E)
	var config := _surface_config()
	var state := MobiusWorld.default_rotation_state(MainScene.RING_LENGTH)
	state["change_timer"] = 0.01
	state["twist_speed"] = 0.16
	state["target_twist_speed"] = 0.16
	state["twist_amplitude"] = 0.24
	state["target_twist_amplitude"] = 0.24
	state["pivot"] = Vector2(MainScene.RING_LENGTH * 0.5, 0.0)
	state["target_pivot"] = Vector2(MainScene.RING_LENGTH * 0.5, 0.0)
	var initial_target_pivot: Vector2 = state.get("target_pivot", Vector2.ZERO)
	var initial_target_speed := float(state.get("target_twist_speed", 0.0))
	var next := MobiusWorld.advance_rotation_state(state, 0.02, config)
	var next_target_pivot: Vector2 = next.get("target_pivot", Vector2.ZERO)
	var next_target_speed := float(next.get("target_twist_speed", 0.0))
	if next_target_pivot.distance_to(initial_target_pivot) < 0.20:
		_fail("Mobius surface twist randomization should choose a new hidden pivot.")
		return
	if absf(next_target_speed) < 0.08 or absf(next_target_speed - initial_target_speed) < 0.008:
		_fail("Mobius surface twist randomization should choose a meaningful angular speed; got %.4f." % next_target_speed)
		return
	var camera := Vector2.ZERO
	var probe_coord := Vector2(2.8, 1.65)
	var before := MobiusWorld.project_to_screen(probe_coord, camera, config, state)
	var previous_pivot: Vector2 = next.get("pivot", Vector2.ZERO)
	var smoothed := next
	var monotonic_motion := false
	for i in range(10):
		smoothed = MobiusWorld.advance_rotation_state(smoothed, 0.04, config)
		var current_pivot: Vector2 = smoothed.get("pivot", Vector2.ZERO)
		if current_pivot.distance_to(previous_pivot) > 0.001:
			monotonic_motion = true
		previous_pivot = current_pivot
	var after := MobiusWorld.project_to_screen(probe_coord, camera, config, smoothed)
	var screen_motion := Vector2(before.get("position", Vector2.ZERO)).distance_to(Vector2(after.get("position", Vector2.ZERO)))
	var depth_motion := absf(float(before.get("depth01", 0.5)) - float(after.get("depth01", 0.5)))
	if not monotonic_motion:
		_fail("Mobius surface twist pivot should interpolate instead of jumping to a static value.")
		return
	if screen_motion < 1.0 and depth_motion < 0.006:
		_fail("Mobius square grid projection should visibly change as twist state evolves; screen=%.3f depth=%.4f." % [screen_motion, depth_motion])
		return
	if float(smoothed.get("change_timer", 0.0)) < 0.0:
		_fail("Mobius twist timer should be reset into the configured interval.")
		return
	print("MOBIUS_SURFACE_MOTION_RANDOMIZED_PROBE ok speed=%.3f pivot_delta=%.2f motion=%.2f depth=%.4f" % [next_target_speed, next_target_pivot.distance_to(initial_target_pivot), screen_motion, depth_motion])
	quit()
