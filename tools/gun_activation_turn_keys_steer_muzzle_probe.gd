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


func _generic_module(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == "gun_activate":
			return part
	return {}


func _first_rifle(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_gun_muscle(part, "muscle") and String(part.get("gun_kind", main._gun_kind_for_data(part))) == "rifle":
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
	return segment


func _make_fixture(main) -> Dictionary:
	var module_part := _generic_module(main)
	var gun_part := _first_rifle(main)
	if module_part.is_empty() or gun_part.is_empty():
		_fail("Missing generic gun module or rifle catalog part.")
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
		"unit_name": "Gun Turn Key Probe",
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
				_gun_segment(gun_part),
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
	main.active_units[1]["hero"] = fighter
	main.all_units = [fighter]

	_release_actions()
	Input.action_press("p1_attack_1")
	main._start_runtime_gun_activation(1, "p1", 0, "p1_attack_1", binding)
	await process_frame

	var before_direction: Vector2 = main.gun_activation_state[1].get("aim_direction", Vector2.RIGHT)
	var before_target_angle := float(fighter.target_facing_angle)
	Input.action_press("p1_face_right")
	Input.action_press("p1_up")
	main._handle_player_battle_input(1, 0.25, "p1")
	var after_direction: Vector2 = main.gun_activation_state[1].get("aim_direction", before_direction)
	var delta := wrapf(after_direction.angle() - before_direction.angle(), -PI, PI)
	if delta <= 0.001:
		_fail("Turn Right key should rotate active gun aim to the right; delta=%.4f." % delta)
	var event: Dictionary = main._runtime_gun_activation_event_for(1)
	if event.is_empty() or not bool(event.get("projectile", false)):
		_fail("Active turn-key gun aim should keep producing a projectile event while movement is held.")
	if String(main.gun_activation_state[1].get("aim_input_mode", "")) != "turn_keys":
		_fail("Runtime gun activation should declare turn-key aim input mode.")
	if absf(wrapf(float(fighter.target_facing_angle) - before_target_angle, -PI, PI)) > 0.001 or bool(fighter.turn_input_active):
		_fail("Turn keys should be reserved by active gun aim and must not rotate torso.")
	if signf(fighter.velocity.y) != -1.0:
		_fail("Movement keys should still move while shooting; velocity.y=%.4f." % fighter.velocity.y)
	var gun_segment: Dictionary = fighter.runtime_world_segment_for_node(2, true)
	var gun_dir := Vector2(gun_segment.get("b", Vector2.RIGHT)) - Vector2(gun_segment.get("a", Vector2.ZERO))
	if gun_dir.length() <= 0.01 or gun_dir.normalized().distance_to(after_direction.normalized()) > 0.035:
		_fail("Dynamic gun segment should rotate with aim direction; segment=%s aim=%s." % [str(gun_dir), str(after_direction)])

	Input.action_release("p1_face_right")
	Input.action_release("p1_up")
	before_direction = after_direction
	Input.action_press("p1_right")
	main._handle_player_battle_input(1, 0.25, "p1")
	after_direction = main.gun_activation_state[1].get("aim_direction", before_direction)
	if after_direction.distance_to(before_direction) > 0.001:
		_fail("Movement Right should not steer gun aim during activation; before=%s after=%s." % [str(before_direction), str(after_direction)])

	_release_actions()
	print("GUN_ACTIVATION_TURN_KEYS_STEER_MUZZLE_PROBE ok delta=%.4f" % delta)
	quit()
