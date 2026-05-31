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
	var coord := Vector2(MainScene.RING_LENGTH * 0.75, -1.5)
	var rotation_state := {"angle": 1.7, "angular_velocity": 0.9, "pivot": Vector2(8.0, 2.0)}
	var right := MobiusWorld.screen_input_to_local(Vector2.RIGHT, coord, config, rotation_state)
	var up := MobiusWorld.screen_input_to_local(Vector2.UP, coord, config, rotation_state)
	if right.distance_to(Vector2.RIGHT) > 0.001:
		_fail("Visual Möbius rotation must not reinterpret screen-right input.")
	if up.distance_to(Vector2.UP) > 0.001:
		_fail("Visual Möbius rotation must not reinterpret screen-up input.")
	print("MOBIUS_FAIR_INPUT_PROBE ok")
	quit()
