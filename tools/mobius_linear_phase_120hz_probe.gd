extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _angle_delta(a: float, b: float) -> float:
	return absf(wrapf(a - b, -PI, PI))


func _init() -> void:
	var config := MobiusWorld.default_config(
		MainScene.RING_LENGTH,
		MainScene.BATTLE_HALF_HEIGHT * 2.0,
		MainScene.VIEW_WIDTH,
		MainScene.VIEW_HEIGHT,
		Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	)
	config["mobius_visual_update_hz"] = 120.0
	config["rotation_blend_seconds"] = 4.0
	config["twist_wave_speed"] = 0.15
	config["ridge_phase_speed"] = 0.18
	config["ridge_angle_speed"] = 0.045
	var state := MobiusWorld.default_rotation_state(MainScene.RING_LENGTH)
	state["change_timer"] = 9.0
	state["twist_speed"] = 0.15
	state["target_twist_speed"] = 0.15
	state["ridge_speed"] = 0.18
	state["target_ridge_speed"] = 0.18
	state["ridge_angle_speed"] = 0.045
	state["target_ridge_angle_speed"] = 0.045
	state["twist_phase"] = 0.21
	state["ridge_phase"] = -0.16
	state["ridge_angle_phase"] = 0.33
	var delta := 0.233
	var substepped := MobiusWorld.advance_rotation_state_substepped(state, delta, config)
	var manual := state.duplicate(true)
	var step := 1.0 / 120.0
	var remaining := delta
	while remaining > 0.000001:
		var dt := minf(step, remaining)
		manual = MobiusWorld.advance_rotation_state(manual, dt, config)
		remaining -= dt
	if _angle_delta(float(substepped.get("twist_phase", 0.0)), float(manual.get("twist_phase", 0.0))) > 0.0001:
		_fail("Substepped twist phase should match explicit 120Hz integration.")
		return
	if _angle_delta(float(substepped.get("ridge_phase", 0.0)), float(manual.get("ridge_phase", 0.0))) > 0.0001:
		_fail("Substepped ridge phase should match explicit 120Hz integration.")
		return
	if _angle_delta(float(substepped.get("ridge_angle_phase", 0.0)), float(manual.get("ridge_angle_phase", 0.0))) > 0.0001:
		_fail("Substepped ridge angle phase should match explicit 120Hz integration.")
		return
	var expected_twist := wrapf(float(state.get("twist_phase", 0.0)) + 0.15 * delta, -TAU, TAU)
	var expected_ridge := wrapf(float(state.get("ridge_phase", 0.0)) + 0.18 * delta, -TAU, TAU)
	var expected_angle := wrapf(float(state.get("ridge_angle_phase", 0.0)) + 0.045 * delta, -TAU, TAU)
	if _angle_delta(float(substepped.get("twist_phase", 0.0)), expected_twist) > 0.0001:
		_fail("Twist phase should advance linearly while speed is stable.")
		return
	if _angle_delta(float(substepped.get("ridge_phase", 0.0)), expected_ridge) > 0.0001:
		_fail("Ridge phase should advance linearly while speed is stable.")
		return
	if _angle_delta(float(substepped.get("ridge_angle_phase", 0.0)), expected_angle) > 0.0001:
		_fail("Ridge angle phase should advance linearly while speed is stable.")
		return
	print("MOBIUS_LINEAR_PHASE_120HZ_PROBE ok twist=%.4f ridge=%.4f angle=%.4f" % [
		float(substepped.get("twist_phase", 0.0)),
		float(substepped.get("ridge_phase", 0.0)),
		float(substepped.get("ridge_angle_phase", 0.0)),
	])
	quit()
