extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


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
	config["frame_rotation_strength"] = 0.58
	var camera_coord := Vector2(2.0, 0.25)
	var coord := Vector2(3.2, 1.1)
	var state_a := {"angle": 0.0, "pivot": Vector2(2.0, 0.0)}
	var state_b := {"angle": 0.95, "pivot": Vector2(8.0, -1.7)}
	var frame_a := MobiusWorld.frame_at(coord, camera_coord, config, state_a)
	var frame_b := MobiusWorld.frame_at(coord, camera_coord, config, state_b)
	var tangent_a: Vector2 = frame_a.get("tangent_screen", Vector2.RIGHT)
	var tangent_b: Vector2 = frame_b.get("tangent_screen", Vector2.RIGHT)
	var width_a: Vector2 = frame_a.get("width_screen", Vector2.DOWN)
	var width_b: Vector2 = frame_b.get("width_screen", Vector2.DOWN)
	if tangent_a.length() < 0.9 or tangent_b.length() < 0.9 or width_a.length() < 0.9 or width_b.length() < 0.9:
		_fail("Rotating frame axes should stay normalized.")
	if tangent_a.distance_to(tangent_b) < 0.015 and width_a.distance_to(width_b) < 0.015:
		_fail("Rotation state and pivot should alter the tangent/width screen frame.")
	var center_projection := MobiusWorld.project_to_screen(camera_coord, camera_coord, config, state_b)
	if Vector2(center_projection.get("position", Vector2.ZERO)).distance_to(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)).get_center()) > 0.01:
		_fail("Camera-local coordinate should remain fixed at screen center; camera must not rotate.")
	print("MOBIUS_ROTATING_FRAME_PROBE ok tangent_delta=%.4f width_delta=%.4f" % [tangent_a.distance_to(tangent_b), width_a.distance_to(width_b)])
	quit()
