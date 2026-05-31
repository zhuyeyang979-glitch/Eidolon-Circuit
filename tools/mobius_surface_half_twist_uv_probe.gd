extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _mirror_weight(u: float) -> float:
	return 0.5 - 0.5 * cos(PI * u)


func _init() -> void:
	if absf(_mirror_weight(0.0)) > 0.001:
		_fail("Mobius texture should start unmirrored.")
		return
	if absf(_mirror_weight(1.0) - 1.0) > 0.001:
		_fail("Mobius texture should be vertically mirrored after one loop.")
		return
	if absf(_mirror_weight(2.0)) > 0.001:
		_fail("Mobius texture should return unmirrored after two loops.")
		return
	var shader_file := FileAccess.open("res://shaders/mobius_strip_surface.gdshader", FileAccess.READ)
	if shader_file == null:
		_fail("Mobius surface shader is missing.")
		return
	var shader_source := shader_file.get_as_text()
	if not shader_source.contains("1.0 - tiled_uv.y") or not shader_source.contains("cos(twist)"):
		_fail("Mobius surface shader should blend normal and vertically mirrored texture samples by continuous U.")
		return
	for needle in ["u_shear", "v_warp", "twist_uv_shear", "twist_uv_warp"]:
		if not shader_source.contains(needle):
			_fail("Mobius surface shader should include %s so the surface art twists inside the rectangular projection." % needle)
			return
	var config := MobiusWorld.default_config(
		MainScene.RING_LENGTH,
		MainScene.BATTLE_HALF_HEIGHT * 2.0,
		MainScene.VIEW_WIDTH,
		MainScene.VIEW_HEIGHT,
		Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	)
	var samples := MobiusWorld.surface_sample_grid(Vector2(MainScene.RING_LENGTH, 0.0), config, {"twist_phase": 0.0})
	var found_after_loop := false
	for raw_sample in samples:
		var sample: Dictionary = raw_sample
		var uvs: PackedVector2Array = sample.get("uvs", PackedVector2Array())
		for uv in uvs:
			if uv.x > 1.0:
				found_after_loop = true
				break
		if found_after_loop:
			break
	if not found_after_loop:
		_fail("Surface UVs should expose lifted U values beyond one loop for half-twist sampling.")
		return
	print("MOBIUS_SURFACE_HALF_TWIST_UV_PROBE ok weights %.2f %.2f %.2f" % [_mirror_weight(0.0), _mirror_weight(1.0), _mirror_weight(2.0)])
	quit()
