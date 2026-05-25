extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _drain_loading(main, expected_state: String, max_ticks: int = 180) -> void:
	for _i in range(max_ticks):
		if main.game_state != MainScene.STATE_LOADING:
			break
		main.tick_loading_tasks(0.016, 6000)
	if main.game_state != expected_state:
		_fail("Loading target mismatch. expected=%s actual=%s" % [expected_state, String(main.game_state)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = true
	if main.game_state == MainScene.STATE_LOADING:
		_drain_loading(main, MainScene.STATE_MENU)
	main._begin_battle(MainScene.MODE_PVP, true)
	main._toggle_battle_runtime_menu()
	if not main.battle_runtime_menu_buttons.has("input"):
		_fail("Battle runtime menu has no Inputs button.")
	var button: Button = main.battle_runtime_menu_buttons["input"]
	if button.disabled or not button.visible:
		_fail("Battle runtime Inputs button is not available.")
	button.pressed.emit()
	if main.game_state == MainScene.STATE_LOADING:
		_drain_loading(main, MainScene.STATE_SETTINGS)
	if main.game_state != MainScene.STATE_SETTINGS:
		_fail("Battle runtime Inputs should navigate to Settings.")
	if main.settings_category != "input":
		_fail("Battle runtime Inputs should remain on input category after loading, got %s." % main.settings_category)
	if main.battle_input_buttons.is_empty():
		_fail("Battle runtime Inputs should display rebind buttons.")
	print("BATTLE_RUNTIME_INPUT_BUTTON_ROUTE_PROBE ok entries=%d" % main.battle_input_buttons.size())
	quit(0)
