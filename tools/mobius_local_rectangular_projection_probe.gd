extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _project(config: Dictionary, s: float, v: float, state: Dictionary) -> Vector2:
	return MobiusWorld.project_to_screen(Vector2(s, v), Vector2.ZERO, config, state).get("position", Vector2.ZERO)


func _init() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	var config := MobiusWorld.default_config(MainScene.RING_LENGTH, MainScene.BATTLE_HALF_HEIGHT * 2.0, MainScene.VIEW_WIDTH, MainScene.VIEW_HEIGHT, rect)
	config["screen_scale"] = rect.size.y / MainScene.VIEW_HEIGHT
	config["local_rectangular_projection"] = true
	config["twist_visual_enabled"] = true
	var state := {"twist_phase": 1.1, "twist_amplitude": 0.4}
	var expected_step := float(config["screen_scale"])
	var y_step_a := _project(config, 0.0, 1.0, state).y - _project(config, 0.0, 0.0, state).y
	var y_step_b := _project(config, MainScene.RING_LENGTH * 0.37, 1.0, state).y - _project(config, MainScene.RING_LENGTH * 0.37, 0.0, state).y
	if absf(y_step_a - expected_step) > 0.01:
		_fail("Local rectangular projection should keep lane height constant at camera; expected %.3f got %.3f." % [expected_step, y_step_a])
		return
	if absf(y_step_b - expected_step) > 0.01:
		_fail("Local rectangular projection should not let twist/depth alter lane height; expected %.3f got %.3f." % [expected_step, y_step_b])
		return
	var x_step := _project(config, 1.0, 0.0, state).x - _project(config, 0.0, 0.0, state).x
	if absf(x_step - expected_step) > 0.01:
		_fail("Local rectangular projection should keep s width constant; expected %.3f got %.3f." % [expected_step, x_step])
		return
	print("MOBIUS_LOCAL_RECTANGULAR_PROJECTION_PROBE ok step=%.3f" % expected_step)
	quit()
