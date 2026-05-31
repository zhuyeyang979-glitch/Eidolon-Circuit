extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MenuControllerScript := preload("res://scripts/controllers/menu_controller.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	if main.battle_runtime_menu_buttons.size() != MenuControllerScript.BATTLE_RUNTIME_OPTION_SPECS.size():
		_fail("Battle runtime options should be generated from controller specs.")
	main.battle_mode = MainScene.MODE_AI
	main._update_battle_runtime_menu_ui()
	if not (main.battle_runtime_menu_buttons["dummy_state"] as Button).disabled:
		_fail("Dummy state option should be disabled outside training.")
	main.battle_mode = MainScene.MODE_TRAINING
	main.training_dummy_state = "idle_brake"
	main._update_battle_runtime_menu_ui()
	var dummy_button := main.battle_runtime_menu_buttons["dummy_state"] as Button
	if dummy_button.disabled:
		_fail("Dummy state option should be enabled in training.")
	var before_text := dummy_button.text
	main._battle_runtime_menu_action("dummy_state")
	main._update_battle_runtime_menu_ui()
	if before_text == dummy_button.text:
		_fail("Dummy state text should update after cycling state.")
	print("BATTLE_RUNTIME_OPTIONS_TABLE_PROBE ok")
	quit(0)
