extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	if main.game_state == MainScene.STATE_LOADING:
		main._show_menu(true)
	main._hover_menu_item(3)
	if main.menu_index != 3 or int(main.menu_controller.selected_index) != 3:
		_fail("Hover should update MenuController selected index and legacy menu_index.")
	if main.menu_ai_seat_panel == null or not main.menu_ai_seat_panel.visible:
		_fail("AI battle menu entry should show seat panel.")
	main._activate_menu_item(3)
	if main.game_state != MainScene.STATE_MENU:
		_fail("AI battle menu entry should only expose seat panel until a seat is clicked.")
	main._start_ai_battle_from_menu(2)
	if main.ai_battle_seat != 2:
		_fail("AI seat button should preserve selected seat.")
	if main.game_state != MainScene.STATE_SCOUT:
		_fail("AI seat button should route into scout/config.")
	main._show_menu()
	main._activate_menu_item(1)
	if main.game_state != MainScene.STATE_SAVED_UNITS:
		_fail("Saved Units menu action should open saved units.")
	main._show_menu()
	main._activate_menu_item(2)
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Unit Edit menu action should open editor.")
	print("MAIN_MENU_TABLE_ACTIONS_PROBE ok")
	quit(0)
