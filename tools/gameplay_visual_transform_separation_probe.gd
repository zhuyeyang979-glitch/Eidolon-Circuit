extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")
const GameplayTransform := preload("res://scripts/gameplay_transform.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var config := MobiusWorld.default_config(
		MainScene.RING_LENGTH,
		MainScene.BATTLE_HALF_HEIGHT * 2.0,
		MainScene.VIEW_WIDTH,
		MainScene.VIEW_HEIGHT,
		Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	)
	config["local_rectangular_projection"] = true
	config["twist_visual_enabled"] = true
	var camera_coord := Vector2(3.0, 0.0)
	var gameplay_a := Vector2(3.2, 0.4)
	var gameplay_b := Vector2(4.4, -0.2)
	var delta_a := GameplayTransform.delta(gameplay_a, gameplay_b, MainScene.RING_LENGTH)
	var ray_a: Dictionary = GameplayTransform.projectile_ray(gameplay_a, Vector2.RIGHT, 2.0)
	var gap_a := main._collider_gap(
		{"shape": "circle", "center": gameplay_a, "radius": 0.25},
		{"shape": "circle", "center": gameplay_b, "radius": 0.25}
	)
	var visual_0 := MobiusWorld.project_to_screen(gameplay_b, camera_coord, config, {"twist_phase": 0.0, "twist_amplitude": 0.18, "pivot": Vector2.ZERO})
	var visual_1 := MobiusWorld.project_to_screen(gameplay_b, camera_coord, config, {"twist_phase": 1.35, "twist_amplitude": 0.18, "pivot": Vector2(9.0, -2.0)})
	var visual_shift := Vector2(visual_0.get("position", Vector2.ZERO)).distance_to(Vector2(visual_1.get("position", Vector2.ZERO)))
	if visual_shift > 0.001:
		_fail("Local rectangular projection should keep gameplay screen position stable under visual rotation.")
	var scale_shift := absf(float(visual_0.get("scale", 1.0)) - float(visual_1.get("scale", 1.0)))
	var depth_shift := absf(float(visual_0.get("depth01", 0.5)) - float(visual_1.get("depth01", 0.5)))
	if maxf(scale_shift, depth_shift) <= 0.001:
		_fail("Möbius visual rotation should still affect depth/scale presentation, not gameplay geometry.")
	var delta_b := GameplayTransform.delta(gameplay_a, gameplay_b, MainScene.RING_LENGTH)
	var ray_b: Dictionary = GameplayTransform.projectile_ray(gameplay_a, Vector2.RIGHT, 2.0)
	var gap_b := main._collider_gap(
		{"shape": "circle", "center": gameplay_a, "radius": 0.25},
		{"shape": "circle", "center": gameplay_b, "radius": 0.25}
	)
	if delta_a.distance_to(delta_b) > 0.001:
		_fail("Gameplay delta must not depend on visual rotation.")
	if Vector2(ray_a.get("end", Vector2.ZERO)).distance_to(Vector2(ray_b.get("end", Vector2.ZERO))) > 0.001:
		_fail("Gameplay projectile ray must not depend on visual rotation.")
	if absf(gap_a - gap_b) > 0.001:
		_fail("Gameplay collision gap must not depend on visual rotation.")
	print("GAMEPLAY_VISUAL_TRANSFORM_SEPARATION_PROBE ok visual_shift=%.3f depth_shift=%.3f" % [visual_shift, depth_shift])
	quit()
