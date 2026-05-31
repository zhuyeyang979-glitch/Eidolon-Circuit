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


func _module_part(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == "gun_activate":
			return part
	return {}


func _sniper_part(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_gun_muscle(part, "muscle") and String(part.get("gun_kind", main._gun_kind_for_data(part))) == "sniper" and String(part.get("ammo_kind", main._ammo_kind_for_data(part))) == "bullet":
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
	segment["radius"] = maxf(0.02, float(part.get("radius", 0.05)))
	segment["terminal_weapon_kind"] = "ranged"
	segment["projectile"] = true
	segment["projectile_only"] = true
	segment["joint_output_momentum_base"] = 80.0
	segment["joint_drive_allocation"] = 80.0
	segment["momentum_min"] = 20.0
	segment["momentum_max"] = 120.0
	return segment


func _make_fixture(main) -> Dictionary:
	var module_part := _module_part(main)
	var sniper_part := _sniper_part(main)
	if module_part.is_empty() or sniper_part.is_empty():
		_fail("Missing generic gun activation module or sniper part.")
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [1, 2],
		"module_action_profile": "gun_activate",
		"module_part": module_part.duplicate(true),
		"joint_drive_allocation_by_node": {"2": 80.0},
	}
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Turn Key Aim Movement Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"max_health": 100,
			"mass": 32.0,
			"move_speed": 4.0,
			"move_acceleration": 30.0,
			"turn_speed": 3.2,
			"turn_command_rate": 3.2,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_index": 0, "part_kind": "torso", "a_local": Vector2(-0.35, 0.0), "b_local": Vector2(0.0, 0.0), "radius": 0.22},
				{"node_index": 1, "part_index": 1, "part_kind": "limb", "a_local": Vector2(0.0, 0.0), "b_local": Vector2(0.7, 0.0), "radius": 0.07},
				_gun_segment(sniper_part),
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
	var before_direction: Vector2 = main.gun_activation_state[1].get("aim_direction", Vector2.RIGHT)
	Input.action_press("p1_right")
	main._handle_player_battle_input(1, 0.25, "p1")
	var after_move_direction: Vector2 = main.gun_activation_state[1].get("aim_direction", before_direction)
	if after_move_direction.distance_to(before_direction) > 0.001:
		_fail("Movement-right should move the unit, not steer turn-key gun aim.")
	var actual_move: Vector2 = fighter.get_meta("actual_move_input_vector", Vector2.ZERO)
	if actual_move.distance_to(Vector2.RIGHT) > 0.001:
		_fail("Movement-right should remain locomotion during turn-key gun aim; actual=%s." % str(actual_move))
	if fighter.velocity.x <= 0.0:
		_fail("Movement-right should create positive locomotion velocity when no firing recoil is applied; velocity=%s." % str(fighter.velocity))

	Input.action_release("p1_right")
	var before_face_angle := float(fighter.target_facing_angle)
	before_direction = after_move_direction
	Input.action_press("p1_face_left")
	main._handle_player_battle_input(1, 0.25, "p1")
	var after_turn_direction: Vector2 = main.gun_activation_state[1].get("aim_direction", before_direction)
	if wrapf(after_turn_direction.angle() - before_direction.angle(), -PI, PI) >= -0.001:
		_fail("Face-left should steer active gun aim left.")
	if absf(wrapf(float(fighter.target_facing_angle) - before_face_angle, -PI, PI)) > 0.001 or bool(fighter.turn_input_active):
		_fail("Face-left should be reserved by gun aim and not rotate the torso.")

	_release_actions()
	print("TURN_KEY_GUN_AIM_DOES_NOT_CONSUME_MOVEMENT_PROBE ok")
	quit()
