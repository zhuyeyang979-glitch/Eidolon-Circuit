extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var config := MobiusWorld.default_config(
		MainScene.RING_LENGTH,
		MainScene.BATTLE_HALF_HEIGHT * 2.0,
		MainScene.VIEW_WIDTH,
		MainScene.VIEW_HEIGHT,
		Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	)
	config["screen_scale"] = 720.0 / MainScene.VIEW_HEIGHT
	config["ridge_depth_strength"] = 1.0
	var camera := Vector2(4.0, 0.0)
	var state := {"ridge_phase": 0.48, "ridge_angle_phase": 0.10, "twist_phase": 0.24, "pivot_influence": 0.0}
	var params := MobiusWorld.surface_shader_parameters(camera, config, state)
	var world_size: Vector2 = params.get("surface_view_world_size", Vector2(MainScene.VIEW_WIDTH, MainScene.VIEW_HEIGHT))
	for raw_uv in [Vector2(0.18, 0.22), Vector2(0.5, 0.5), Vector2(0.78, 0.66)]:
		var uv: Vector2 = raw_uv
		var coord: Vector2 = camera + (uv * 2.0 - Vector2.ONE) * world_size * 0.5
		var field := MobiusWorld.surface_field_at(coord, camera, config, state)
		var shader_sample := MobiusWorld.surface_sample_coord_from_screen_uv(uv, camera, config, state)
		if absf(float(field.get("ridge_distance01", -1.0)) - float(shader_sample.get("ridge_distance01", -2.0))) > 0.0001:
			_fail("CPU field and full-rect shader model must share ridge distance at UV %s." % str(uv))
			return
		if absf(float(field.get("depth01", -1.0)) - float(shader_sample.get("depth01", -2.0))) > 0.0001:
			_fail("CPU field and full-rect shader model must share depth at UV %s." % str(uv))
			return
	print("MOBIUS_DOUBLE_RIDGE_FIELD_CONSISTENCY_PROBE ok")
	quit()
