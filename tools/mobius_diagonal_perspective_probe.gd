extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_close(label: String, a: float, b: float, tolerance: float = 0.015) -> void:
	if absf(a - b) > tolerance:
		_fail("%s expected close values %.4f and %.4f" % [label, a, b])


func _init() -> void:
	var screen_rect := Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	var config := MobiusWorld.default_config(
		MainScene.RING_LENGTH,
		MainScene.BATTLE_HALF_HEIGHT * 2.0,
		MainScene.VIEW_WIDTH,
		MainScene.VIEW_HEIGHT,
		screen_rect
	)
	var camera_coord := Vector2.ZERO
	var x := 2.4
	var y := 1.3
	var state := {"angle": 0.0, "pivot": Vector2(MainScene.RING_LENGTH * 0.5, 0.0)}
	var tl := MobiusWorld.project_to_screen(Vector2(-x, -y), camera_coord, config, state)
	var br := MobiusWorld.project_to_screen(Vector2(x, y), camera_coord, config, state)
	var tr := MobiusWorld.project_to_screen(Vector2(x, -y), camera_coord, config, state)
	var bl := MobiusWorld.project_to_screen(Vector2(-x, y), camera_coord, config, state)
	var tl_depth := float(tl.get("depth01", 0.0))
	var br_depth := float(br.get("depth01", 0.0))
	var tr_depth := float(tr.get("depth01", 0.0))
	var bl_depth := float(bl.get("depth01", 0.0))
	_assert_close("near diagonal depth", tl_depth, br_depth)
	_assert_close("far diagonal depth", tr_depth, bl_depth)
	if tl_depth <= tr_depth + 0.08:
		_fail("One diagonal should be visibly nearer/larger than the opposite diagonal.")
	_assert_close("near diagonal scale", float(tl.get("scale", 0.0)), float(br.get("scale", 0.0)))
	_assert_close("far diagonal scale", float(tr.get("scale", 0.0)), float(bl.get("scale", 0.0)))
	var rotated := MobiusWorld.project_to_screen(Vector2(-x, -y), camera_coord, config, {"angle": PI * 0.35, "pivot": Vector2(4.0, 1.2)})
	if absf(float(rotated.get("depth01", 0.0)) - tl_depth) < 0.02:
		_fail("Rotation state and pivot should alter diagonal depth.")
	print("MOBIUS_DIAGONAL_PERSPECTIVE_PROBE ok near=%.3f far=%.3f" % [tl_depth, tr_depth])
	quit()
