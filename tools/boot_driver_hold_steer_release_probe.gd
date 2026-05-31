extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const ProbeLib := preload("res://tools/boot_driver_probe_lib.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	_release_actions()
	quit(1)


func _release_actions() -> void:
	for action in ["p1_up", "p1_down", "p1_left", "p1_right", "p1_face_left", "p1_face_right", "p1_attack_1"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _pose(fighter, node_index: int) -> Dictionary:
	var world: Dictionary = fighter.runtime_world_segment_for_node(node_index, true)
	return {
		"a": world.get("a", Vector2.ZERO),
		"b": world.get("b", Vector2.ZERO),
		"axis": Vector2(world.get("axis", Vector2.RIGHT)).normalized() if world.has("axis") else (Vector2(world.get("b", Vector2.RIGHT)) - Vector2(world.get("a", Vector2.ZERO))).normalized(),
	}


func _pose_matches(a: Dictionary, b: Dictionary) -> bool:
	return Vector2(a["a"]).distance_to(Vector2(b["a"])) <= 0.015 and Vector2(a["b"]).distance_to(Vector2(b["b"])) <= 0.015 and Vector2(a["axis"]).distance_to(Vector2(b["axis"])) <= 0.03


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	ProbeLib.prepare_main(main)
	var fixture := ProbeLib.build_fixture(main)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, fixture["unit_bp"])
	var bindings: Array = Array(stats.get("runtime_module_bindings", []))
	if bindings.is_empty():
		_fail("Boot Driver runtime binding missing.")
		return
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "BOOT_DRIVER_HOLD", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	main.active_units = {1: {"hero": fighter, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	main.all_units = [fighter]
	var before_limb := _pose(fighter, int(fixture["limb"]))
	var before_weapon := _pose(fighter, int(fixture["weapon"]))
	_release_actions()
	Input.action_press("p1_attack_1")
	main._start_runtime_held_melee_activation(1, "p1", 0, "p1_attack_1", Dictionary(bindings[0]), Vector2.ZERO)
	if fighter.runtime_module_actions.size() != 1:
		_fail("Boot Driver did not create one held runtime action.")
		return
	var action: Dictionary = fighter.runtime_module_actions[0]
	var duration := float(action.get("duration", 0.0))
	var startup_ratio := float(action.get("startup_ratio", 0.0))
	if not is_equal_approx(startup_ratio, 0.333333):
		_fail("Boot Driver startup ratio should be 1/3.")
		return
	fighter._tick_runtime_module_actions(duration)
	action = fighter.runtime_module_actions[0]
	var startup_floor := duration * (1.0 - startup_ratio)
	if absf(float(action.get("timer", 0.0)) - startup_floor) > 0.01 or bool(action.get("hold_released", true)):
		_fail("Boot Driver should hold at startup end while attack is held: %s" % str(action))
		return
	var before_face_angle := float(fighter.target_facing_angle)
	var before_steer := float(action.get("boot_driver_steer_angle", 0.0))
	await process_frame
	Input.action_press("p1_face_right")
	main._handle_player_battle_input(1, 0.25, "p1")
	Input.action_release("p1_face_right")
	action = fighter.runtime_module_actions[0]
	if float(action.get("boot_driver_steer_angle", 0.0)) <= before_steer + 0.01:
		_fail("Face-right should steer the Boot Driver rotating joint.")
		return
	if absf(wrapf(float(fighter.target_facing_angle) - before_face_angle, -PI, PI)) > 0.001 or bool(fighter.turn_input_active):
		_fail("Boot Driver turn keys should be reserved from torso facing while held.")
		return
	Input.action_release("p1_attack_1")
	main._handle_player_battle_input(1, 0.1, "p1")
	if fighter.runtime_module_actions.is_empty():
		_fail("Boot Driver action vanished before recovery could run.")
		return
	action = fighter.runtime_module_actions[0]
	if not bool(action.get("hold_released", false)):
		_fail("Boot Driver release did not enter recovery.")
		return
	if float(action.get("timer", duration)) > startup_floor + 0.01:
		_fail("Boot Driver recovery timer should be the 2/3 recovery window.")
		return
	fighter._tick_runtime_module_actions(duration * 2.0)
	if not fighter.runtime_module_actions.is_empty():
		_fail("Boot Driver recovery did not finish.")
		return
	if not _pose_matches(before_limb, _pose(fighter, int(fixture["limb"]))) or not _pose_matches(before_weapon, _pose(fighter, int(fixture["weapon"]))):
		_fail("Boot Driver did not restore entry pose after recovery.")
		return
	_release_actions()
	print("BOOT_DRIVER_HOLD_STEER_RELEASE_PROBE ok")
	quit()
