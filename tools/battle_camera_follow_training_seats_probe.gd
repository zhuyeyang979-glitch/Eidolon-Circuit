extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _unit(owner: int, s_value: float):
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({"owner_id": owner, "role": "hero", "stats": {"health": 100, "mass": 12.0}})
	unit.deploy(fposmod(s_value, MainScene.RING_LENGTH), 0.0)
	unit.mobius_s = s_value
	unit.mobius_v = 0.0
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	main.mobius_enabled = true
	var left = _unit(1, MainScene.RING_LENGTH + 1.0)
	var right = _unit(2, MainScene.RING_LENGTH + 3.0)
	main.active_units[1]["hero"] = left
	main.active_units[2]["hero"] = right
	main.all_units = [left, right]
	main.ai_battle_seat = 1
	main._update_camera_center()
	if absf(main.camera_mobius_s - left.mobius_s) > 0.001:
		_fail("Seat 1 camera did not follow P1 canonical coordinate.")
	main.ai_battle_seat = 2
	main._update_camera_center()
	if absf(main.camera_mobius_s - right.mobius_s) > 0.001:
		_fail("Seat 2 camera did not follow P2 canonical coordinate.")
	main.ai_battle_seat = 3
	main.spectator_view_mode = MainScene.SPECTATOR_VIEW_MID
	main.spectator_camera_center = MainScene.RING_LENGTH + 1.0
	for i in range(80):
		main._update_camera_center()
	if absf(main.camera_mobius_s - (MainScene.RING_LENGTH + 2.0)) > 0.03:
		_fail("Spectator midpoint camera did not converge on canonical midpoint.")
	print("BATTLE_CAMERA_FOLLOW_TRAINING_SEATS_PROBE ok")
	quit()
