extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.mobius_enabled = true
	main.camera_mobius_s = MainScene.RING_LENGTH + 0.1
	main.camera_center = 0.1
	main.camera_lane_center = 0.0
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({"owner_id": 1, "role": "hero", "stats": {"health": 100, "mass": 12.0, "move_speed": 4.0, "move_acceleration": 30.0}})
	for s_value in [MainScene.RING_LENGTH - 0.04, MainScene.RING_LENGTH + 0.04, MainScene.RING_LENGTH * 2.0 + 0.04]:
		unit.deploy(s_value, 0.2)
		unit.mobius_s = s_value
		unit.mobius_v = 0.2
		for raw in [Vector2.UP, Vector2.DOWN]:
			var actual: Vector2 = main._battle_movement_vector_for_unit(unit, raw).get("actual", Vector2.ZERO)
			if absf(actual.y) <= 0.001 or signf(actual.y) != signf(raw.y):
				_fail("Vertical input changed sign at s=%.3f raw=%s actual=%s." % [s_value, str(raw), str(actual)])
	print("BATTLE_MOBIUS_VERTICAL_SIGN_ACROSS_SEAM_PROBE ok")
	quit()
