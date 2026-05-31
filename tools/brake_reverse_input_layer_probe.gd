extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	_cleanup_input()
	quit(1)


func _cleanup_input() -> void:
	for action in ["p1_left", "p1_right", "p1_up", "p1_down"]:
		Input.action_release(action)


func _make_unit():
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "InputLayerReverseProbe",
		"stats": {
			"health": 100,
			"mass": 10.0,
			"thruster_drive_demand": 60.0,
			"thruster_effective_drive_demand": 60.0,
			"thruster_boost_extra_demand": 60.0,
			"thruster_boost_peak_demand": 120.0,
			"thruster_effective_boost_peak_demand": 120.0,
			"engine_drive_chain_ratio": 1.0,
			"engine_boost_chain_ratio": 1.0,
			"move_momentum": 60.0,
			"body_move_speed": 2.0,
			"move_speed": 2.0,
			"thruster_acceleration": 24.0,
			"boost_momentum": 60.0,
			"boost_total_momentum": 120.0,
			"boost_speed": 12.0,
			"boost_duration": 0.3,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso"}],
		},
	})
	unit.deploy(0.0, 0.0)
	unit.set_facing_immediate(1)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit = _make_unit()
	main.active_units = {
		1: {"hero": unit, "puppet": [], "barrier": null},
		2: {"hero": null, "puppet": [], "barrier": null},
	}
	unit.velocity = Vector2.RIGHT * 1.0
	Input.action_press("p1_left", 1.0)
	main._handle_player_battle_input(1, 0.2, "p1")
	if unit.velocity.length() > 0.001:
		_fail("Held reverse input should brake to stop through battle input layer.")
		return
	main._handle_player_battle_input(1, 0.1, "p1")
	if unit.velocity.x < -0.001:
		_fail("Continuing to hold reverse before release/repress should not reverse drive.")
		return
	Input.action_release("p1_left")
	main._handle_player_battle_input(1, 0.05, "p1")
	Input.action_press("p1_left", 1.0)
	main._handle_player_battle_input(1, 0.1, "p1")
	if unit.velocity.x >= -0.001:
		_fail("Release and re-press should allow normal reverse drive.")
		return
	if String(unit.get_meta("last_move_command_mode", "")) not in ["reverse", "drive"]:
		_fail("Expected last_move_command_mode=reverse/drive after release-repress reverse movement.")
		return
	_cleanup_input()
	print("BRAKE_REVERSE_INPUT_LAYER_PROBE ok")
	quit()
