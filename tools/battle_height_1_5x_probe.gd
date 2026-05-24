extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if absf(MainScene.BATTLE_HALF_HEIGHT - 7.5) > 0.001:
		_fail("Main battle half-height should be 7.5.")
		return
	if absf(FighterScene.BATTLE_HALF_HEIGHT - 7.5) > 0.001:
		_fail("Fighter battle half-height should be 7.5.")
		return
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({"owner_id": 1, "role": "hero", "stats": {"health": 100, "mass": 12.0, "move_speed": 4.0, "move_acceleration": 30.0}})
	unit.deploy(2.0, 7.2)
	if unit.lane < 7.0:
		_fail("Unit should be allowed in the expanded y range.")
		return
	unit.deploy(2.0, 9.0)
	if absf(unit.lane - 7.5) > 0.001:
		_fail("Unit y should clamp at expanded half-height 7.5, got %.3f." % unit.lane)
		return
	var main = MainScene.new()
	root.add_child(main)
	if absf(main._camera_lane_center_limit() - (7.5 - MainScene.VIEW_HEIGHT * 0.5)) > 0.001:
		_fail("Camera lane center limit should account for expanded map height and unchanged view height.")
		return
	print("BATTLE_HEIGHT_1_5X_PROBE ok half=%.1f camera_limit=%.3f" % [MainScene.BATTLE_HALF_HEIGHT, main._camera_lane_center_limit()])
	quit()
