extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MenuControllerScript := preload("res://scripts/controllers/menu_controller.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _menu_index_for_action(action_key: String) -> int:
	for i in range(MenuControllerScript.MAIN_MENU_SPECS.size()):
		var spec: Dictionary = MenuControllerScript.MAIN_MENU_SPECS[i]
		if String(spec.get("key", "")) == action_key:
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	if main.game_state == MainScene.STATE_LOADING:
		main._show_menu(true)
	var local_versus_index := _menu_index_for_action("pvp")
	var computer_battle_index := _menu_index_for_action("show_ai_seat_panel")
	if local_versus_index < 0 or computer_battle_index < 0:
		_fail("Main menu should expose local versus and computer battle entries.")
	if local_versus_index >= computer_battle_index:
		_fail("Local versus should be prioritized before computer battle in the main menu.")
	main._hover_menu_item(computer_battle_index)
	if main.menu_index != computer_battle_index or int(main.menu_controller.selected_index) != computer_battle_index:
		_fail("Hover should update MenuController selected index and legacy menu_index.")
	if main.menu_ai_seat_panel == null or not main.menu_ai_seat_panel.visible:
		_fail("Computer battle menu entry should show seat panel.")
	main._activate_menu_item(computer_battle_index)
	if main.game_state != MainScene.STATE_MENU:
		_fail("Computer battle menu entry should only expose seat panel until a seat is clicked.")
	main._start_ai_battle_from_menu(2)
	if main.ai_battle_seat != 2:
		_fail("Computer battle seat button should preserve selected seat.")
	if main.game_state != MainScene.STATE_SCOUT:
		_fail("Computer battle seat button should route into scout/config.")
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
