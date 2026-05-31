extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const GameplayTransform := preload("res://scripts/gameplay_transform.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var start_screen := Vector2(320.0, 260.0)
	var direction := Vector2(0.8, -0.35).normalized()
	var end_screen: Vector2 = main._gameplay_ray_screen_end(start_screen, direction, 3.0, 80.0)
	var screen_delta := end_screen - start_screen
	if screen_delta.length() <= 0.01:
		_fail("Aim line endpoint should move away from start.")
	if absf(screen_delta.normalized().cross(direction)) > 0.001:
		_fail("Rendered aim line should be a straight screen segment matching gameplay direction.")
	var ray: Dictionary = GameplayTransform.projectile_ray(Vector2(1.0, 0.0), direction, 3.0)
	var gameplay_delta := Vector2(ray.get("end", Vector2.ZERO)) - Vector2(ray.get("start", Vector2.ZERO))
	if absf(gameplay_delta.normalized().cross(direction)) > 0.001:
		_fail("Projectile gameplay ray should use the same Euclidean direction as the aim line.")
	print("AIM_LINE_STRAIGHT_EUCLIDEAN_PROBE ok pixels=%.2f" % screen_delta.length())
	quit()
