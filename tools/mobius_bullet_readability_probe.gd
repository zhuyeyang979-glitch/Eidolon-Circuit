extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")
const GameplayTransform := preload("res://scripts/gameplay_transform.gd")


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
	config["input_frame_strength"] = 0.34
	config["fairness_radius"] = 1.35
	var camera_coord := Vector2(6.0, 0.0)
	var state := {"angle": 1.05, "pivot": Vector2(2.0, 2.0)}
	var aim := Vector2(0.86, -0.28).normalized()
	if MobiusWorld.screen_input_to_local(aim, camera_coord, config, state) != aim:
		_fail("Aim helper should keep active bullet/player aiming in stable camera-space.")
	var gameplay_motion := GameplayTransform.screen_input_to_gameplay_motion(aim)
	if gameplay_motion.distance_to(aim) > 0.001:
		_fail("Gameplay aim/motion should not be altered by visual Möbius rotation.")
	var ray: Dictionary = GameplayTransform.projectile_ray(camera_coord, aim, 3.0)
	var start: Vector2 = ray.get("start", Vector2.ZERO)
	var end: Vector2 = ray.get("end", Vector2.ZERO)
	var mid := start.lerp(end, 0.5)
	var lateral_error := absf((mid - start).cross(aim))
	if lateral_error > 0.001:
		_fail("Gameplay projectile path should be a straight Euclidean ray.")
	var p0 := MobiusWorld.project_to_screen(camera_coord, camera_coord, config, state)
	var center := Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)).get_center()
	if Vector2(p0.get("position", Vector2.ZERO)).distance_to(center) > 0.01:
		_fail("Camera center should not rotate away from screen center.")
	print("MOBIUS_BULLET_READABILITY_PROBE ok ray_len=%.3f aim=%s" % [start.distance_to(end), str(aim)])
	quit()
