extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _drain_loading(main, expected_state: String, max_ticks: int = 160) -> void:
	if main.game_state != MainScene.STATE_LOADING:
		return
	for _i in range(max_ticks):
		main.tick_loading_tasks(0.016, 6000)
		if main.game_state != MainScene.STATE_LOADING:
			break
	if main.game_state != expected_state:
		_fail("Loading target mismatch. expected=%s actual=%s" % [expected_state, String(main.game_state)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main.game_state == MainScene.STATE_LOADING:
		_drain_loading(main, MainScene.STATE_MENU)
	if MainScene.MENU_ITEMS.size() != 7:
		_fail("Main menu should expose seven mature top-level entries.")
	if MainScene.MENU_ITEMS[0] != "开始训练":
		_fail("First main menu item should be training config entry.")
	if MainScene.MENU_ITEMS[2] != "单位编辑":
		_fail("Unit Edit should be the third top-level item.")
	main._activate_menu_item(0)
	_drain_loading(main, MainScene.STATE_SCOUT)
	if main.game_state != MainScene.STATE_SCOUT:
		_fail("Training menu entry should open training config/scout page, not direct battle.")
	if main.pending_battle_mode != MainScene.MODE_TRAINING:
		_fail("Training config page should set pending battle mode to training.")
	if bool(main.training_seat_confirmed):
		_fail("Training seat should not be confirmed before player selects P1/P2/P3.")
	print("MAIN_MENU_NAVIGATION_PROBE ok")
	quit()
