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
	var valley_state := {"ridge_phase": 0.0, "ridge_angle_phase": 0.0, "pivot_influence": 0.0}
	var ridge_state := {"ridge_phase": PI, "ridge_angle_phase": 0.0, "pivot_influence": 0.0}
	var coord := camera
	var valley_projection := MobiusWorld.project_to_screen(coord, camera, config, valley_state)
	var ridge_projection := MobiusWorld.project_to_screen(coord, camera, config, ridge_state)
	if float(ridge_projection.get("scale", 0.0)) <= float(valley_projection.get("scale", 1.0)):
		_fail("Foreground unit scale should still grow on a Mobius ridge.")
		return
	var valley_brightness := float(valley_projection.get("brightness", 0.0))
	var ridge_brightness := float(ridge_projection.get("brightness", 0.0))
	if valley_brightness < 0.959 or ridge_brightness > 1.121 or ridge_brightness <= valley_brightness:
		_fail("Foreground unit brightness should stay in a tight readable range while preserving near/far contrast; got %.3f/%.3f." % [valley_brightness, ridge_brightness])
		return
	if float(ridge_projection.get("grid_brightness", 1.0)) >= valley_brightness:
		_fail("Grid brightness should remain below foreground unit brightness; grid=%.3f unit=%.3f." % [float(ridge_projection.get("grid_brightness", 0.0)), valley_brightness])
		return
	var unit = Fighter.new()
	root.add_child(unit)
	unit.active = true
	unit.set_mobius_screen_projection(ridge_projection, true)
	var applied_brightness := float(unit.get_meta("mobius_surface_brightness", 0.0))
	if absf(applied_brightness - ridge_brightness) > 0.001:
		_fail("Fighter should consume foreground unit brightness exactly; got %.3f expected %.3f." % [applied_brightness, ridge_brightness])
		return
	print("MOBIUS_UNIT_FOREGROUND_CONTRAST_PROBE ok scale=%.3f/%.3f brightness=%.3f/%.3f grid=%.3f" % [float(ridge_projection.get("scale")), float(valley_projection.get("scale")), ridge_brightness, valley_brightness, float(ridge_projection.get("grid_brightness"))])
	quit()
