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
	config["input_frame_strength"] = 0.44
	config["twist_visual_enabled"] = true
	var camera_coord := Vector2(0.0, 0.0)
	var coord := Vector2(1.4, 1.2)
	var screen_input := Vector2.RIGHT
	var raw := MobiusWorld.screen_input_to_local(screen_input, coord, config, {"angle": 1.1})
	if raw != screen_input:
		_fail("Legacy fair-input helper should stay screen-readable.")
	var frame_a := MobiusWorld.frame_at(coord, camera_coord, config, {"angle": 0.0, "pivot": Vector2.ZERO})
	var frame_b := MobiusWorld.frame_at(coord, camera_coord, config, {"angle": 1.2, "pivot": Vector2(7.0, -1.5)})
	var depth_delta := absf(float(frame_a.get("depth01", 0.5)) - float(frame_b.get("depth01", 0.5)))
	var twist_delta := absf(float(frame_a.get("twist_angle", 0.0)) - float(frame_b.get("twist_angle", 0.0)))
	if depth_delta < 0.001 and twist_delta < 0.001:
		_fail("Visual Mobius state should still affect texture/depth cues.")
	config["local_rectangular_projection"] = true
	var pos_a: Vector2 = MobiusWorld.project_to_screen(coord, camera_coord, config, {"angle": 0.0, "pivot": Vector2.ZERO}).get("position", Vector2.ZERO)
	var pos_b: Vector2 = MobiusWorld.project_to_screen(coord, camera_coord, config, {"angle": 1.2, "pivot": Vector2(7.0, -1.5)}).get("position", Vector2.ZERO)
	if pos_a.distance_to(pos_b) > 0.001:
		_fail("Visual Mobius rotation should not move local rectangular gameplay projection.")
	var gameplay_a := GameplayTransform.screen_input_to_gameplay_motion(screen_input)
	var gameplay_b := GameplayTransform.screen_input_to_gameplay_motion(screen_input)
	if gameplay_a != screen_input or gameplay_b != screen_input:
		_fail("Gameplay input must stay screen-readable and must not rotate with the visual frame.")
	print("MOBIUS_INPUT_CONSTRAINT_FRAME_PROBE ok depth_delta=%.4f twist_delta=%.4f gameplay=%s" % [depth_delta, twist_delta, str(gameplay_a)])
	quit()
