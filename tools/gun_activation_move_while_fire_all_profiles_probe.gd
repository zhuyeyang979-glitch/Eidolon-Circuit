extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")

const CASES := [
	{"label": "sniper", "gun_kind": "sniper", "ammo_kind": "bullet", "profile": "gun_activate"},
	{"label": "sprayer", "gun_kind": "sprayer", "ammo_kind": "chemical", "profile": "gun_activate"},
	{"label": "rifle", "gun_kind": "rifle", "ammo_kind": "bullet", "profile": "rifle_burst_activate"},
	{"label": "laser", "gun_kind": "laser_gun", "ammo_kind": "laser", "profile": "laser_beam_activate"},
	{"label": "grenade", "gun_kind": "grenade_launcher", "ammo_kind": "explosive", "profile": "grenade_arc_activate"},
	{"label": "missile", "gun_kind": "missile_launcher", "ammo_kind": "explosive", "profile": "missile_lock_activate"},
	{"label": "web", "gun_kind": "web_gun", "ammo_kind": "web", "profile": "web_tether_activate"},
]


func _fail(message: String) -> void:
	push_error(message)
	_release_actions()
	quit(1)


func _release_actions() -> void:
	for action in ["p1_up", "p1_down", "p1_left", "p1_right", "p1_face_left", "p1_face_right", "p1_attack_1"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _module_part(main, profile: String) -> Dictionary:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == profile:
			return part
	return {}


func _gun_part(main, gun_kind: String, ammo_kind: String) -> Dictionary:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_gun_muscle(part, "muscle"):
			continue
		if String(part.get("gun_kind", main._gun_kind_for_data(part))) == gun_kind and String(part.get("ammo_kind", main._ammo_kind_for_data(part))) == ammo_kind and not main._part_is_catalog_frozen("muscle", part):
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


func _make_fixture(main, firearm: Dictionary) -> Dictionary:
	var profile := String(firearm.get("profile", ""))
	var gun_kind := String(firearm.get("gun_kind", ""))
	var ammo_kind := String(firearm.get("ammo_kind", ""))
	var module_part := _module_part(main, profile)
	var gun_part := _gun_part(main, gun_kind, ammo_kind)
	if module_part.is_empty():
		_fail("Missing gun activation module for profile %s." % profile)
	if gun_part.is_empty():
		_fail("Missing live gun part for %s/%s." % [gun_kind, ammo_kind])
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [1, 2],
		"module_action_profile": profile,
		"module_part": module_part.duplicate(true),
		"joint_drive_allocation_by_node": {"2": 80.0},
	}
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Move While Fire %s" % String(firearm.get("label", profile)),
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


func _assert_case(main, firearm: Dictionary) -> void:
	_release_actions()
	var fixture := _make_fixture(main, firearm)
	var fighter = fixture["fighter"]
	var binding: Dictionary = fixture["binding"]
	main.active_units = {1: {"hero": fighter, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	main.all_units = [fighter]
	Input.action_press("p1_attack_1")
	main._start_runtime_gun_activation(1, "p1", 0, "p1_attack_1", binding)
	await process_frame
	if String(main.gun_activation_state[1].get("aim_input_mode", "")) != "turn_keys":
		_fail("%s activation should use turn-key aim mode." % String(firearm.get("label", "")))
	var before_direction: Vector2 = main.gun_activation_state[1].get("aim_direction", Vector2.RIGHT)
	var before_v := float(fighter.get("mobius_v"))
	Input.action_press("p1_face_right")
	Input.action_press("p1_up")
	main._handle_player_battle_input(1, 0.25, "p1")
	fighter.tick(0.25, MainScene.RING_LENGTH)
	var after_direction: Vector2 = main.gun_activation_state[1].get("aim_direction", before_direction)
	if wrapf(after_direction.angle() - before_direction.angle(), -PI, PI) <= 0.001:
		_fail("%s should rotate aim with the face-right key while firing." % String(firearm.get("label", "")))
	var actual_move: Vector2 = fighter.get_meta("actual_move_input_vector", Vector2.ZERO)
	if actual_move.distance_to(Vector2.UP) > 0.001:
		_fail("%s should keep movement keys assigned to locomotion; actual=%s." % [String(firearm.get("label", "")), str(actual_move)])
	if signf(fighter.velocity.y) != -1.0 or float(fighter.get("mobius_v")) >= before_v:
		_fail("%s should keep moving upward while firing; velocity=%s mobius_v %.4f -> %.4f." % [String(firearm.get("label", "")), str(fighter.velocity), before_v, float(fighter.get("mobius_v"))])
	var event: Dictionary = main._runtime_gun_activation_event_for(1)
	if event.is_empty() or not bool(event.get("projectile", false)):
		_fail("%s should still expose a projectile event while moving and firing." % String(firearm.get("label", "")))
	_release_actions()
	main.gun_activation_state[1] = {}
	fighter.queue_free()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	for firearm in CASES:
		await _assert_case(main, firearm)
	print("GUN_ACTIVATION_MOVE_WHILE_FIRE_ALL_PROFILES_PROBE ok count=%d" % CASES.size())
	quit()
