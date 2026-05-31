extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	seed(12031)
	var config := MobiusWorld.default_config(
		MainScene.RING_LENGTH,
		MainScene.BATTLE_HALF_HEIGHT * 2.0,
		MainScene.VIEW_WIDTH,
		MainScene.VIEW_HEIGHT,
		Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	)
	config["rotation_interval_min"] = 30.0
	config["rotation_interval_max"] = 60.0
	config["rotation_blend_seconds"] = 4.0
	config["twist_visual_enabled"] = true
	config["twist_wave_speed"] = 0.10
	config["twist_wave_amplitude"] = 0.18
	var state := {
		"angle": 0.0,
		"angular_velocity": 0.0,
		"target_angular_velocity": 0.0,
		"twist_phase": 0.0,
		"twist_speed": 0.10,
		"target_twist_speed": 0.10,
		"twist_amplitude": 0.18,
		"target_twist_amplitude": 0.18,
		"pivot": Vector2(1.0, 0.0),
		"target_pivot": Vector2(1.0, 0.0),
		"change_timer": 0.05,
	}
	var stable_config := config.duplicate(true)
	stable_config["twist_visual_enabled"] = false
	var stable_a := MobiusWorld.project_to_screen(Vector2(2.0, 1.0), Vector2.ZERO, stable_config, state)
	var rotated_state := state.duplicate(true)
	rotated_state["angle"] = 1.7
	rotated_state["angular_velocity"] = 0.9
	var stable_b := MobiusWorld.project_to_screen(Vector2(2.0, 1.0), Vector2.ZERO, stable_config, rotated_state)
	if Vector2(stable_a.get("position", Vector2.ZERO)).distance_to(Vector2(stable_b.get("position", Vector2.ZERO))) > 0.001:
		_fail("Mobius background state should no longer rotate stable gameplay projection.")
	var before_projection := MobiusWorld.project_to_screen(Vector2(2.0, 1.0), Vector2.ZERO, config, state)
	var next := MobiusWorld.advance_rotation_state(state, 0.10, config)
	if float(next.get("change_timer", 0.0)) < 29.0 or float(next.get("change_timer", 0.0)) > 61.0:
		_fail("Twist timer should reschedule into the configured 30-60s interval.")
	if absf(float(next.get("angle", 999.0))) > 0.001 or absf(float(next.get("angular_velocity", 999.0))) > 0.001:
		_fail("Mobius visual state should not rotate the background.")
	if absf(float(next.get("target_twist_speed", 0.0))) <= 0.001 or float(next.get("target_twist_amplitude", 0.0)) <= 0.001:
		_fail("Twist timer should keep a slow wave speed and amplitude.")
	for i in range(30):
		next = MobiusWorld.advance_rotation_state(next, 0.2, config)
	var after_projection := MobiusWorld.project_to_screen(Vector2(2.0, 1.0), Vector2.ZERO, config, next)
	if Vector2(after_projection.get("position", Vector2.ZERO)).distance_to(Vector2(before_projection.get("position", Vector2.ZERO))) < 1.0 and absf(float(after_projection.get("depth01", 0.0)) - float(before_projection.get("depth01", 0.0))) < 0.01:
		_fail("Slow twist state should visibly alter the Mobius surface projection.")
	print("MOBIUS_VISUAL_ROTATION_TIMER_PROBE ok timer=%.2f phase=%.3f angle=%.3f" % [float(next.get("change_timer", 0.0)), float(next.get("twist_phase", 0.0)), float(next.get("angle", 0.0))])
	quit()
