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
	config["local_rectangular_projection"] = true
	var camera := Vector2(1.4, 0.0)
	var coord := Vector2(2.0, -0.45)
	var a := MobiusWorld.project_to_screen(coord, camera, config, {"ridge_phase": 0.0, "ridge_angle_phase": 0.0, "pivot_influence": 0.0})
	var b := MobiusWorld.project_to_screen(coord, camera, config, {"ridge_phase": PI, "ridge_angle_phase": 0.0, "pivot_influence": 0.0})
	if Vector2(a.get("position", Vector2.ZERO)).distance_to(Vector2(b.get("position", Vector2.ZERO))) > 0.001:
		_fail("Visual ridge motion must not move a gameplay unit anchor.")
		return
	if absf(float(a.get("scale", 1.0)) - float(b.get("scale", 1.0))) < 0.01:
		_fail("Stable anchors should still inherit changing surface depth presentation.")
		return
	print("MOBIUS_UNIT_ANCHOR_STABILITY_PROBE ok scale_shift=%.3f" % absf(float(a.get("scale")) - float(b.get("scale"))))
	quit()
