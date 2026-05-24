extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _mirror_weight(u: float) -> float:
	return 0.5 - 0.5 * cos(PI * u)


func _twisted_sample_v(u: float, v: float) -> float:
	var mirror := _mirror_weight(u)
	return lerpf(v, 1.0 - v, mirror)


func _twist_shear(u: float, v: float) -> float:
	return (v - 0.5) * sin(PI * u) * 0.055


func _init() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	var config := MobiusWorld.default_config(
		MainScene.RING_LENGTH,
		MainScene.BATTLE_HALF_HEIGHT * 2.0,
		MainScene.VIEW_WIDTH,
		MainScene.VIEW_HEIGHT,
		rect
	)
	config["local_rectangular_projection"] = true
	config["surface_segments"] = 24
	config["width_segments"] = 5
	var camera := Vector2(4.0, 0.0)
	var state := {"twist_phase": 0.35}
	var p_a := MobiusWorld.project_to_screen(Vector2(3.0, -1.2), camera, config, state)
	var p_b := MobiusWorld.project_to_screen(Vector2(5.0, -1.2), camera, config, state)
	var p_c := MobiusWorld.project_to_screen(Vector2(5.0, 1.2), camera, config, state)
	var screen_a: Vector2 = p_a.get("position", Vector2.ZERO)
	var screen_b: Vector2 = p_b.get("position", Vector2.ZERO)
	var screen_c: Vector2 = p_c.get("position", Vector2.ZERO)
	if absf(screen_a.y - screen_b.y) > 0.001:
		_fail("Local projection should keep equal lane values on the same screen height.")
		return
	var expected_step := rect.size.y / MainScene.VIEW_HEIGHT * 2.4
	var actual_step := absf(screen_c.y - screen_b.y)
	if expected_step > 0.0 and absf(actual_step - expected_step) > 0.01:
		_fail("Rectangular projection should preserve lane spacing; expected %.3f got %.3f." % [expected_step, actual_step])
		return
	if absf(_twisted_sample_v(1.0, 0.22) - 0.78) > 0.001:
		_fail("One Mobius loop should vertically mirror texture V.")
		return
	if absf(_twisted_sample_v(2.0, 0.22) - 0.22) > 0.001:
		_fail("Two Mobius loops should restore texture V.")
		return
	if absf(_twist_shear(0.5, 0.8)) <= 0.001:
		_fail("Half-loop texture sampling should include shear so art visibly twists inside the rectangle.")
		return
	var shader_file := FileAccess.open("res://shaders/mobius_strip_surface.gdshader", FileAccess.READ)
	if shader_file == null:
		_fail("Mobius surface shader is missing.")
		return
	var shader_source := shader_file.get_as_text()
	for needle in ["u_shear", "v_warp", "twist_uv_shear", "twist_uv_warp", "repeat_enable"]:
		if not shader_source.contains(needle):
			_fail("Mobius surface shader should include %s for textured rectangular twist." % needle)
			return
	print("MOBIUS_RECT_PROJECTION_TEXTURE_TWIST_PROBE ok")
	quit()
