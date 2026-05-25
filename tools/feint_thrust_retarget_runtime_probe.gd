extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _module_part(main) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", "module", "DUEL ROUTER: FEINT THRUST")
	if index < 0:
		_fail("Missing DUEL ROUTER: FEINT THRUST module.")
		return {}
	return main._selected_component("hero", "module", index)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var part := _module_part(main)
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [0],
		"module_action_profile": "rapier_feint_thrust",
		"module_part": part.duplicate(true),
		"joint_drive_allocation_by_node": {"0": 100.0},
		"allocated_limb_momentum_by_node": {"0": 100.0},
	}
	fighter.setup_unit({
		"unit_name": "Feint Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 30.0,
			"move_speed": 2.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{
				"node_index": 0,
				"part_index": 0,
				"part_kind": "limb_muscle",
				"name": "Probe Rapier Arm",
				"a_local": Vector2.ZERO,
				"b_local": Vector2(0.72, 0.0),
				"axis_local": Vector2.RIGHT,
				"radius": 0.05,
				"damage_type": "pierce",
				"material_class": "weapon",
				"contact_damage_mult": 0.18,
				"damage_coeff": 0.18,
				"runtime_topology": true,
			}],
			"runtime_module_bindings": [binding],
		},
	})
	fighter.deploy(0.0, 0.0)
	var event := fighter.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("FEINT THRUST failed to start: %s" % String(fighter.get_meta("last_module_gate_reason", "")))
	fighter.set_meta("gameplay_move_input_vector", Vector2.UP)
	fighter._tick_runtime_module_actions(0.03)
	if fighter.runtime_module_actions.is_empty():
		_fail("FEINT THRUST action ended during startup.")
	var action: Dictionary = Dictionary(fighter.runtime_module_actions[0])
	var retarget: Vector2 = action.get("feint_retarget_direction", Vector2.RIGHT)
	var angle_deg := absf(rad_to_deg(Vector2.RIGHT.angle_to(retarget)))
	if angle_deg < 8.0 or angle_deg > 18.6:
		_fail("FEINT THRUST retarget should clamp near 18 deg; got %.2f." % angle_deg)
	var world := fighter.runtime_world_segment_for_node(0, true)
	var axis: Vector2 = Vector2(world.get("b", Vector2.RIGHT)) - Vector2(world.get("a", Vector2.ZERO))
	var world_angle := absf(rad_to_deg(Vector2.RIGHT.angle_to(axis.normalized())))
	if world_angle < 8.0 or world_angle > 18.6:
		_fail("FEINT THRUST runtime segment did not use retarget direction; got %.2f." % world_angle)
	print("FEINT_THRUST_RETARGET_RUNTIME_PROBE ok angle=%.2f" % angle_deg)
	quit()
