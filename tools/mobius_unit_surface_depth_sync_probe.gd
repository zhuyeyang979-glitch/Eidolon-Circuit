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
		_fail("A unit on a ridge should appear larger than the same anchored unit in a valley.")
		return
	if float(ridge_projection.get("brightness", 0.0)) <= float(valley_projection.get("brightness", 1.0)):
		_fail("A unit on a ridge should appear brighter than one in a valley.")
		return
	var unit = Fighter.new()
	root.add_child(unit)
	unit.set_mobius_screen_projection(ridge_projection, true)
	if absf(unit.scale.x - float(ridge_projection.get("scale", 1.0))) > 0.001:
		_fail("Fighter display scale should consume the exact surface scale on first projection.")
		return
	if absf(float(unit.get_meta("mobius_surface_brightness", 0.0)) - float(ridge_projection.get("brightness", 0.0))) > 0.001:
		_fail("Fighter visual brightness should match the surface field beneath its anchor.")
		return
	print("MOBIUS_UNIT_SURFACE_DEPTH_SYNC_PROBE ok scale=%.3f/%.3f brightness=%.3f/%.3f" % [float(ridge_projection.get("scale")), float(valley_projection.get("scale")), float(ridge_projection.get("brightness")), float(valley_projection.get("brightness"))])
	quit()
