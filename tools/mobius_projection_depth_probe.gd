extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


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
	var near_projection := MobiusWorld.project_to_screen(Vector2.ZERO, camera_coord, config, {"angle": 0.0})
	var far_projection := MobiusWorld.project_to_screen(Vector2(MainScene.RING_LENGTH * 0.5, 0.0), camera_coord, config, {"angle": 0.0})
	var near_scale := float(near_projection.get("scale", 0.0))
	var far_scale := float(far_projection.get("scale", 0.0))
	var near_depth := float(near_projection.get("depth01", -1.0))
	var far_depth := float(far_projection.get("depth01", -1.0))
	if near_scale <= far_scale:
		_fail("Near strip segment should render larger than far segment; near %.3f far %.3f" % [near_scale, far_scale])
	if near_depth <= far_depth:
		_fail("Near strip segment should have greater depth01 than far segment; near %.3f far %.3f" % [near_depth, far_depth])
	if int(near_projection.get("z_index", 0)) <= int(far_projection.get("z_index", 0)):
		_fail("Near strip segment should sort above far segment.")
	if not bool(near_projection.get("visible", false)):
		_fail("Camera-local strip projection should be visible.")
	print("MOBIUS_PROJECTION_DEPTH_PROBE ok scale %.3f > %.3f depth %.3f > %.3f" % [near_scale, far_scale, near_depth, far_depth])
	quit()
