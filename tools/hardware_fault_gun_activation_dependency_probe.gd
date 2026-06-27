extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")

const GUN_NODE_ID := 2


func _fail(message: String) -> void:
	push_error(message)
	_release_actions()
	quit(1)


func _release_actions() -> void:
	for action in ["p1_attack_1"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _module_part(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == "gun_activate":
			return part
	return {}


func _gun_part(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_gun_muscle(part, "muscle") and String(part.get("gun_kind", main._gun_kind_for_data(part))) == "sprayer":
			return part
	return {}


func _gun_segment(part: Dictionary) -> Dictionary:
	var segment := part.duplicate(true)
	segment["node_index"] = GUN_NODE_ID
	segment["part_index"] = GUN_NODE_ID
	segment["part_kind"] = "terminal"
	segment["a_local"] = Vector2(0.7, 0.0)
	segment["b_local"] = Vector2(1.35, 0.0)
	segment["axis_local"] = Vector2.RIGHT
	segment["radius"] = maxf(0.02, float(part.get("radius", 0.05)))
	segment["terminal_weapon_kind"] = "ranged"
	segment["projectile"] = true
	segment["projectile_only"] = true
	segment["runtime_momentum_capacity"] = 10.0
	segment["joint_output_momentum_base"] = 80.0
	segment["joint_drive_allocation"] = 80.0
	segment["momentum_min"] = 20.0
	segment["momentum_max"] = 120.0
	return segment


func _make_fixture(main) -> Dictionary:
	var module_part := _module_part(main)
	var gun_part := _gun_part(main)
	if module_part.is_empty() or gun_part.is_empty():
		_fail("Missing gun activation module or sprayer gun part.")
		return {}
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [1, GUN_NODE_ID],
		"module_action_profile": "gun_activate",
		"module_part": module_part.duplicate(true),
		"joint_drive_allocation_by_node": {str(GUN_NODE_ID): 80.0},
	}
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Gun Fault Dependency Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"unit_id": "gun-fault-dependency",
			"health": 100,
			"max_health": 100,
			"mass": 32.0,
			"move_speed": 4.0,
			"move_acceleration": 30.0,
			"turn_speed": 3.2,
			"turn_command_rate": 3.2,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_index": 0, "part_kind": "torso", "a_local": Vector2(-0.35, 0.0), "b_local": Vector2(0.0, 0.0), "radius": 0.22, "runtime_momentum_capacity": 80.0},
				{"node_index": 1, "part_index": 1, "part_kind": "limb", "a_local": Vector2(0.0, 0.0), "b_local": Vector2(0.7, 0.0), "radius": 0.07, "runtime_momentum_capacity": 40.0},
				_gun_segment(gun_part),
			],
			"runtime_module_bindings": [binding],
		},
	})
	fighter.deploy(2.0, 0.0)
	return {"fighter": fighter, "binding": binding}


func _fault_gun(main, fighter, binding: Dictionary) -> void:
	var body_id: String = main._hardware_fault_construct_body_id(fighter, binding)
	main.hardware_fault_state_table = {
		body_id: {
			GUN_NODE_ID: {
				"state": "faulted",
				"runtime_momentum_capacity": 10.0,
				"transition_sequence": 1,
			},
		},
	}
	main._sync_hardware_fault_runtime_state_to_unit(fighter)


func _assert_start_blocked_by_fault(main, fighter, binding: Dictionary) -> void:
	_fault_gun(main, fighter, binding)
	main._start_runtime_gun_activation(1, "p1", 0, "p1_attack_1", binding)
	if main._runtime_gun_activation_active(1):
		_fail("Faulted gun dependency should block gun activation startup.")
	var reason := String(fighter.get_meta("last_module_gate_reason", ""))
	if not reason.contains("hardware") or not reason.contains("faulted"):
		_fail("Faulted gun startup should record a hardware fault gate reason, got: %s" % reason)


func _assert_active_activation_clears_when_faulted(main, fighter, binding: Dictionary) -> void:
	main._reset_hardware_fault_runtime_state()
	Input.action_press("p1_attack_1")
	main._start_runtime_gun_activation(1, "p1", 0, "p1_attack_1", binding)
	if not main._runtime_gun_activation_active(1):
		_fail("Normal gun dependency should start activation before fault injection.")
	_fault_gun(main, fighter, binding)
	main._tick_runtime_gun_activation(1, "p1", 0.12)
	if main._runtime_gun_activation_active(1):
		_fail("Active gun activation should clear when its gun dependency becomes faulted.")
	var reason := String(fighter.get_meta("last_module_gate_reason", ""))
	if not reason.contains("hardware") or not reason.contains("faulted"):
		_fail("Active fault cancellation should record a hardware fault gate reason, got: %s" % reason)
	_release_actions()


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	main._reset_hardware_fault_runtime_state()
	var fixture := _make_fixture(main)
	var fighter = fixture["fighter"]
	var binding: Dictionary = fixture["binding"]
	main.active_units = {1: {"hero": fighter, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	main.all_units = [fighter]
	main._start_runtime_gun_activation(1, "p1", 0, "p1_attack_1", binding)
	if not main._runtime_gun_activation_active(1):
		_fail("Probe fixture should start gun activation before hardware fault state is applied.")
	main.gun_activation_state[1] = {}
	_assert_start_blocked_by_fault(main, fighter, binding)
	_assert_active_activation_clears_when_faulted(main, fighter, binding)
	print("HARDWARE_FAULT_GUN_ACTIVATION_DEPENDENCY_PROBE ok")
	quit(0)
