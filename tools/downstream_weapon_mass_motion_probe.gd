extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _fighter_with_terminal(terminal_mass: float, terminal_length: float):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "DOWNSTREAM_MASS_PROBE",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 40.0 + terminal_mass,
			"runtime_topology_segments": [
				{
					"node_index": 1,
					"part_kind": "limb_muscle",
					"a_local": Vector2.ZERO,
					"b_local": Vector2(0.65, 0.0),
					"mass": 6.0,
					"allocated_limb_momentum": 42.0,
					"joint_output_momentum_base": 160.0,
					"momentum_min": 0.0,
					"momentum_max": 180.0,
				},
				{
					"node_index": 2,
					"part_kind": "terminal",
					"a_local": Vector2(0.65, 0.0),
					"b_local": Vector2(0.65 + terminal_length, 0.0),
					"mass": terminal_mass,
				},
			],
			"runtime_topology_edges": [
				{"a_node": 1, "a_socket": "distal", "b_node": 2, "b_socket": "root_joint"},
			],
		},
	})
	return fighter


func _init() -> void:
	var module_part := {"startup_ratio": 1.0 / 3.0, "recovery_ratio": 2.0 / 3.0}
	var binding := {"target_nodes": [1], "allocated_limb_momentum_by_node": {"1": 42.0}}
	var light = _fighter_with_terminal(2.0, 0.25)
	var heavy = _fighter_with_terminal(30.0, 0.95)
	var light_budget: Dictionary = light._runtime_action_motion_budget([1], module_part, 180.0, 0.0, 1.0, "normal", binding)
	var heavy_budget: Dictionary = heavy._runtime_action_motion_budget([1], module_part, 180.0, 0.0, 1.0, "normal", binding)
	var light_duration := float(light_budget.get("duration", 0.0))
	var heavy_duration := float(heavy_budget.get("duration", 0.0))
	if heavy_duration <= light_duration * 1.5:
		_fail("Heavy downstream weapon should slow the same limb: light %.3f heavy %.3f" % [light_duration, heavy_duration])
	if float(heavy_budget.get("driven_mass", 0.0)) <= float(light_budget.get("driven_mass", 0.0)):
		_fail("Driven mass should include downstream terminal mass.")
	print("DOWNSTREAM_WEAPON_MASS_MOTION_PROBE ok light=%.3f heavy=%.3f" % [light_duration, heavy_duration])
	quit()
