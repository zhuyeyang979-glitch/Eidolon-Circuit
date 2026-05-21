extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if MainScene.MENU_ITEMS.size() != 7:
		_fail("Main menu should expose seven mature top-level entries.")
	if MainScene.MENU_ITEMS[0] != "开始训练":
		_fail("First main menu item should be training config entry.")
	if MainScene.MENU_ITEMS[2] != "队伍编辑":
		_fail("TeamEdit should be the third top-level item.")
	main._activate_menu_item(0)
	if main.game_state != MainScene.STATE_SCOUT:
		_fail("Training menu entry should open training config/scout page, not direct battle.")
	if main.pending_battle_mode != MainScene.MODE_TRAINING:
		_fail("Training config page should set pending battle mode to training.")
	if bool(main.training_seat_confirmed):
		_fail("Training seat should not be confirmed before player selects P1/P2/P3.")
	print("MAIN_MENU_NAVIGATION_PROBE ok")
	quit()
