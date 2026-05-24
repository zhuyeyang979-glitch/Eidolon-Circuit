extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MenuViewScript := preload("res://scripts/views/menu_view.gd")
const MenuControllerScript := preload("res://scripts/controllers/menu_controller.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	if main.menu_view == null or not (main.menu_view is MenuViewScript):
		_fail("Main scene should initialize MenuView.")
	if main.menu_controller == null or not (main.menu_controller is MenuControllerScript):
		_fail("Main scene should initialize MenuController.")
	if main.menu_buttons.size() != MenuControllerScript.MAIN_MENU_SPECS.size():
		_fail("Main menu button count should be generated from controller specs.")
	for key in ["back", "main_menu", "settings", "help", "close"]:
		if not main.page_options_buttons.has(key):
			_fail("Page options missing spec key: %s" % key)
	for key in ["continue", "reset_positions", "reset_resources", "dummy_state", "input", "settings", "training_config", "main_menu"]:
		if not main.battle_runtime_menu_buttons.has(key):
			_fail("Battle runtime options missing spec key: %s" % key)
	if main.menu_buttons != main.menu_view.menu_buttons:
		_fail("Legacy main.menu_buttons should alias MenuView buttons.")
	if main.page_options_buttons != main.menu_view.page_options_buttons:
		_fail("Legacy page_options_buttons should alias MenuView buttons.")
	if main.battle_runtime_menu_buttons != main.menu_view.battle_runtime_menu_buttons:
		_fail("Legacy battle_runtime_menu_buttons should alias MenuView buttons.")
	print("MENU_VIEW_CONTROLLER_CONTRACT_PROBE ok")
	quit(0)
