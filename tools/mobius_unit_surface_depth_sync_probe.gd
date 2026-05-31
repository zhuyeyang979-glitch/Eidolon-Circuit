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
	var state_a := {"ridge_phase": 0.0, "ridge_angle_phase": 0.0, "pivot_influence": 0.0}
	var state_b := {"ridge_phase": PI, "ridge_angle_phase": 1.2, "pivot_influence": 0.7}
	var coord := Vector2(MainScene.RING_LENGTH * 0.25, 0.0)
	var stable_a := MobiusWorld.project_to_screen(coord, camera, config, state_a)
	var stable_b := MobiusWorld.project_to_screen(coord, camera, config, state_b)
	if absf(float(stable_a.get("scale", 0.0)) - float(stable_b.get("scale", 1.0))) > 0.001:
		_fail("Unit scale should be stable across ridge/ripple phase changes; got %.4f/%.4f." % [float(stable_a.get("scale", 0.0)), float(stable_b.get("scale", 0.0))])
		return
	var far_coord := Vector2(MainScene.RING_LENGTH * 0.5, 0.0)
	var far_projection := MobiusWorld.project_to_screen(far_coord, camera, config, state_a)
	if float(stable_a.get("scale", 0.0)) <= float(far_projection.get("scale", 1.0)):
		_fail("Stable Mobius depth should still make near-loop units larger than far-loop units.")
		return
	var unit = Fighter.new()
	root.add_child(unit)
	unit.set_mobius_screen_projection(stable_a, true)
	if absf(unit.scale.x - float(stable_a.get("scale", 1.0))) > 0.001:
		_fail("Fighter display scale should consume the exact stable Mobius scale on first projection.")
		return
	if absf(float(unit.get_meta("mobius_surface_brightness", 0.0)) - float(stable_a.get("brightness", 0.0))) > 0.001:
		_fail("Fighter visual brightness should match the stable Mobius depth field.")
		return
	print("MOBIUS_UNIT_SURFACE_DEPTH_SYNC_PROBE ok stable=%.3f far=%.3f brightness=%.3f" % [float(stable_a.get("scale")), float(far_projection.get("scale")), float(stable_a.get("brightness"))])
	quit()
