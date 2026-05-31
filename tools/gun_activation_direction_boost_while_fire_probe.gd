extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	_release_actions()
	quit(1)


func _release_actions() -> void:
	for action in ["p1_up", "p1_down", "p1_left", "p1_right", "p1_face_left", "p1_face_right", "p1_attack_1"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _part(main, slot_key: String, predicate: Callable) -> Dictionary:
	for i in range(main._catalog_for("hero", slot_key).size()):
		var part: Dictionary = main._selected_component("hero", slot_key, i)
		if bool(predicate.call(part)):
			return part
	return {}


func _gun_segment(part: Dictionary) -> Dictionary:
	var segment := part.duplicate(true)
	segment["node_index"] = 2
	segment["part_index"] = 2
	segment["part_kind"] = "terminal"
	segment["a_local"] = Vector2(0.7, 0.0)
	segment["b_local"] = Vector2(1.35, 0.0)
	segment["axis_local"] = Vector2.RIGHT
	segment["terminal_weapon_kind"] = "ranged"
	segment["projectile"] = true
	segment["projectile_only"] = true
	segment["joint_output_momentum_base"] = 80.0
	segment["joint_drive_allocation"] = 80.0
	return segment


func _make_fixture(main) -> Dictionary:
	var module_part := _part(main, "module", func(part: Dictionary) -> bool: return String(part.get("module_action_profile", "")) == "rifle_burst_activate")
	var rifle_part := _part(main, "muscle", func(part: Dictionary) -> bool:
		return main._component_is_gun_muscle(part, "muscle") and String(part.get("gun_kind", main._gun_kind_for_data(part))) == "rifle"
	)
	if module_part.is_empty() or rifle_part.is_empty():
		_fail("Missing rifle module or rifle terminal.")
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [1, 2],
		"module_action_profile": "rifle_burst_activate",
		"module_part": module_part.duplicate(true),
		"joint_drive_allocation_by_node": {"2": 80.0},
	}
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Gun Direction Boost Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"max_health": 100,
			"mass": 20.0,
			"move_speed": 4.0,
			"move_acceleration": 30.0,
			"turn_speed": 3.2,
			"turn_command_rate": 3.2,
			"boost_momentum": 160.0,
			"boost_total_momentum": 160.0,
			"boost_speed": 12.0,
			"boost_duration": 0.24,
			"boost_cooldown": 0.4,
			"boost_heat": 6.0,
			"thruster_boost_extra_demand": 40.0,
			"heat_capacity": 100.0,
			"movement_profile": "omni",
			"boost_angle_degrees": 360.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_index": 0, "part_kind": "torso", "a_local": Vector2(-0.35, 0.0), "b_local": Vector2(0.0, 0.0), "radius": 0.22},
				{"node_index": 1, "part_index": 1, "part_kind": "limb", "a_local": Vector2(0.0, 0.0), "b_local": Vector2(0.7, 0.0), "radius": 0.07},
				_gun_segment(rifle_part),
			],
			"runtime_module_bindings": [binding],
		},
	})
	fighter.deploy(2.0, 0.0)
	return {"fighter": fighter, "binding": binding}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	var fixture := _make_fixture(main)
	var fighter = fixture["fighter"]
	var binding: Dictionary = fixture["binding"]
	main.active_units = {1: {"hero": fighter, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	main.all_units = [fighter]
	_release_actions()
	Input.action_press("p1_attack_1")
	main._start_runtime_gun_activation(1, "p1", 0, "p1_attack_1", binding)
	await process_frame
	if not main._runtime_gun_activation_active(1):
		_fail("Gun activation did not start.")
	if not bool(main.gun_activation_state[1].get("direction_boost_while_firing", false)):
		_fail("Gun activation state should allow direction boost while firing.")
	main.gun_activation_state[1]["fire_timer"] = 10.0
	main.last_direction_taps[1]["right"] = Time.get_ticks_msec() * 0.001
	var heat_before := float(fighter.heat)
	Input.action_press("p1_right")
	main._handle_player_battle_input(1, 0.05, "p1")
	if float(fighter.boost_drive_timer) <= 0.0:
		_fail("Direction double-tap should boost while gun activation is held.")
	var heat_event: Dictionary = fighter.get_meta("last_heat_event", {})
	if String(heat_event.get("heat_event_source", "")) != "boost":
		_fail("Gun-fire direction boost should record boost heat event, got %s." % str(heat_event))
	if float(fighter.heat) <= heat_before:
		_fail("Gun-fire direction boost should consume heat.")
	var event: Dictionary = main._runtime_gun_activation_event_for(1)
	if event.is_empty() or not bool(event.get("projectile", false)):
		_fail("Boost while firing should not clear projectile activation event.")
	_release_actions()
	print("GUN_ACTIVATION_DIRECTION_BOOST_WHILE_FIRE_PROBE ok heat=%.1f" % float(fighter.heat))
	quit()
