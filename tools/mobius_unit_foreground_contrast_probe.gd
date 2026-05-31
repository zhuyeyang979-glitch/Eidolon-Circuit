extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")
const Fighter := preload("res://scripts/fighter.gd")


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
	config["local_rectangular_projection"] = true
	config["screen_scale"] = 720.0 / MainScene.VIEW_HEIGHT
	var camera := Vector2.ZERO
	var state := {"ridge_phase": 0.0, "ridge_angle_phase": 0.0, "pivot_influence": 0.0}
	var far_projection := MobiusWorld.project_to_screen(Vector2(MainScene.RING_LENGTH * 0.5, 0.0), camera, config, state)
	var near_projection := MobiusWorld.project_to_screen(Vector2.ZERO, camera, config, state)
	if float(near_projection.get("scale", 0.0)) <= float(far_projection.get("scale", 1.0)):
		_fail("Foreground unit scale should still grow with stable Mobius near/far depth.")
		return
	var far_brightness := float(far_projection.get("brightness", 0.0))
	var near_brightness := float(near_projection.get("brightness", 0.0))
	if far_brightness < 0.959 or near_brightness > 1.121 or near_brightness <= far_brightness:
		_fail("Foreground unit brightness should stay readable while preserving stable near/far contrast; got %.3f/%.3f." % [far_brightness, near_brightness])
		return
	if float(near_projection.get("grid_brightness", 1.0)) >= far_brightness:
		_fail("Grid brightness should remain below foreground unit brightness; grid=%.3f unit=%.3f." % [float(near_projection.get("grid_brightness", 0.0)), far_brightness])
		return
	var unit = Fighter.new()
	root.add_child(unit)
	unit.active = true
	unit.set_mobius_screen_projection(near_projection, true)
	var applied_brightness := float(unit.get_meta("mobius_surface_brightness", 0.0))
	if absf(applied_brightness - near_brightness) > 0.001:
		_fail("Fighter should consume foreground unit brightness exactly; got %.3f expected %.3f." % [applied_brightness, near_brightness])
		return
	print("MOBIUS_UNIT_FOREGROUND_CONTRAST_PROBE ok scale=%.3f/%.3f brightness=%.3f/%.3f grid=%.3f" % [float(near_projection.get("scale")), float(far_projection.get("scale")), near_brightness, far_brightness, float(near_projection.get("grid_brightness"))])
	quit()
