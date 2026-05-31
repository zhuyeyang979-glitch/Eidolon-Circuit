extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_active_input_frame = {"pressed": {"battle_pause": true}, "released": {}}
	main.battle_input_frame_active = true
	main.battle_input_edges_enabled = true
	main._handle_battle_input(MainScene.BATTLE_SIMULATION_DELTA)
	if main.battle_runtime_menu_panel == null or not main.battle_runtime_menu_panel.visible:
		_fail("First substep did not consume pause edge.")
		return
	main.battle_input_edges_enabled = false
	main._handle_battle_input(MainScene.BATTLE_SIMULATION_DELTA)
	if not main.battle_runtime_menu_panel.visible:
		_fail("A single pause edge was consumed twice across substeps.")
		return
	print("BATTLE_INPUT_EDGE_SINGLE_CONSUME_PROBE ok")
	quit(0)
