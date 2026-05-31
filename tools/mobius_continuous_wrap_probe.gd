extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({"stats": {"health": 10, "teamedit_runtime_topology": false}, "owner_id": 1, "role": "hero"})
	unit.deploy(MainScene.RING_LENGTH - 0.05, 1.25)
	unit.velocity = Vector2(1.0, 0.0)
	var before := MobiusWorld.project_to_screen(
		Vector2(unit.mobius_s, unit.mobius_v),
		Vector2(MainScene.RING_LENGTH, 0.0),
		MobiusWorld.default_config(MainScene.RING_LENGTH, MainScene.BATTLE_HALF_HEIGHT * 2.0, MainScene.VIEW_WIDTH, MainScene.VIEW_HEIGHT, Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))),
		{"angle": 0.0}
	)
	unit.tick(0.12, MainScene.RING_LENGTH)
	var after := MobiusWorld.project_to_screen(
		Vector2(unit.mobius_s, unit.mobius_v),
		Vector2(MainScene.RING_LENGTH, 0.0),
		MobiusWorld.default_config(MainScene.RING_LENGTH, MainScene.BATTLE_HALF_HEIGHT * 2.0, MainScene.VIEW_WIDTH, MainScene.VIEW_HEIGHT, Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))),
		{"angle": 0.0}
	)
	if unit.mobius_s <= MainScene.RING_LENGTH:
		_fail("Lifted coordinate should continue beyond RING_LENGTH.")
	if unit.ring_pos >= 0.2:
		_fail("Compatibility ring_pos should wrap after crossing RING_LENGTH.")
	if absf(unit.lane - 1.25) > 0.001 or absf(unit.mobius_v - 1.25) > 0.001:
		_fail("Lane must not suddenly flip at the seam.")
	var screen_delta: float = Vector2(before.get("position", Vector2.ZERO)).distance_to(Vector2(after.get("position", Vector2.ZERO)))
	if screen_delta > 80.0:
		_fail("Projection jumped too far across the seam: %.2f px" % screen_delta)
	print("MOBIUS_CONTINUOUS_WRAP_PROBE ok ring=%.3f lane=%.2f s=%.3f" % [unit.ring_pos, unit.lane, unit.mobius_s])
	quit()
