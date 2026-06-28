extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")

const FAULT_NODE_ID := 2

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	quit(1)


func _module_part(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == "two_link_forward_snap":
			return part
	return {}


func _binding(module_part: Dictionary) -> Dictionary:
	return {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [1, FAULT_NODE_ID],
		"module_action_profile": "two_link_forward_snap",
		"module_part": module_part.duplicate(true),
	}


func _make_fighter(main, unit_id: String) -> Dictionary:
	var module_part := _module_part(main)
	if module_part.is_empty():
		_fail("Missing two_link_forward_snap module part.")
		return {}
	var binding := _binding(module_part)
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Direct Fault Dependency Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"unit_id": unit_id,
			"health": 100,
			"max_health": 100,
			"mass": 32.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_index": 0, "part_kind": "torso", "name": "Probe Core", "a_local": Vector2(-0.35, 0.0), "b_local": Vector2(0.0, 0.0), "radius": 0.22, "runtime_momentum_capacity": 80.0},
				{"node_index": 1, "part_index": 1, "part_kind": "limb_muscle", "name": "Upper Link", "a_local": Vector2(0.0, 0.0), "b_local": Vector2(0.7, 0.0), "radius": 0.07, "runtime_momentum_capacity": 40.0},
				{"node_index": FAULT_NODE_ID, "part_index": FAULT_NODE_ID, "part_kind": "limb_muscle", "name": "Right Connector", "a_local": Vector2(0.7, 0.0), "b_local": Vector2(1.1, 0.0), "radius": 0.07, "runtime_momentum_capacity": 10.0},
			],
			"runtime_module_bindings": [binding],
		},
	})
	fighter.deploy(2.0, 0.0)
	return {"fighter": fighter, "binding": binding}


func _install_main_fixture(main, fighter) -> void:
	main.active_units = {1: {"hero": fighter, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	main.all_units = [fighter]


func _runtime_action_count(fighter) -> int:
	var actions = fighter.get("runtime_module_actions")
	return Array(actions).size() if actions is Array else 0


func _fault_dependency(main, fighter, binding: Dictionary) -> void:
	var body_id: String = main._hardware_fault_construct_body_id(fighter, binding)
	main.hardware_fault_state_table = {
		body_id: {
			FAULT_NODE_ID: {
				"state": "faulted",
				"runtime_momentum_capacity": 10.0,
				"transition_sequence": 1,
			},
		},
	}
	main._sync_hardware_fault_runtime_state_to_unit(fighter)


func _assert_normal_direct_module_starts(main) -> void:
	main._reset_hardware_fault_runtime_state()
	var fixture := _make_fighter(main, "direct-normal")
	var fighter = fixture["fighter"]
	_install_main_fixture(main, fighter)
	main._hero_runtime_module_attack(1, "p1", Vector2.RIGHT, 0, "normal")
	if _runtime_action_count(fighter) <= 0:
		_fail("Normal direct runtime module should start before hardware fault injection.")


func _assert_faulted_direct_module_blocks(main) -> void:
	main._reset_hardware_fault_runtime_state()
	var fixture := _make_fighter(main, "direct-faulted")
	var fighter = fixture["fighter"]
	var binding: Dictionary = fixture["binding"]
	_install_main_fixture(main, fighter)
	_fault_dependency(main, fighter, binding)
	main._hero_runtime_module_attack(1, "p1", Vector2.RIGHT, 0, "normal")
	if _runtime_action_count(fighter) > 0:
		_fail("Faulted direct runtime dependency should block module action startup.")
	var reason := String(fighter.get_meta("last_module_gate_reason", ""))
	if not reason.contains("hardware") or not reason.contains("faulted"):
		_fail("Faulted direct module should record a hardware fault gate reason, got: %s" % reason)
	if not reason.contains("Right Connector"):
		_fail("Faulted direct module should name the first failed hardware dependency, got: %s" % reason)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	_assert_normal_direct_module_starts(main)
	if failed:
		return
	_assert_faulted_direct_module_blocks(main)
	if failed:
		return
	print("HARDWARE_FAULT_DIRECT_MODULE_DEPENDENCY_PROBE ok")
	quit(0)
