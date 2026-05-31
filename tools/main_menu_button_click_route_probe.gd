extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _drain_loading(main, expected_state: String, max_ticks: int = 180) -> void:
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
	if main.menu_view == null:
		_fail("Main scene did not create MenuView.")
	if not main.menu_view.main_menu_pressed.is_connected(Callable(main, "_activate_menu_item")):
		_fail("MenuView main_menu_pressed is not connected to main menu activation.")
	if main.menu_buttons.is_empty() or not (main.menu_buttons[0] is Button):
		_fail("Main menu did not expose the first button.")
	var first_button: Button = main.menu_buttons[0]
	first_button.pressed.emit()
	_drain_loading(main, MainScene.STATE_SCOUT)
	if main.game_state != MainScene.STATE_SCOUT:
		_fail("Main menu button click should open training config/scout, got %s." % String(main.game_state))
	if main.pending_battle_mode != MainScene.MODE_TRAINING:
		_fail("Training button click should set pending battle mode to training.")
	print("MAIN_MENU_BUTTON_CLICK_ROUTE_PROBE ok")
	quit(0)
