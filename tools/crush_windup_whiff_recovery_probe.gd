extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _module_part(main) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", "module", "MONSTER ROUTER: CRUSH WINDUP")
	if index < 0:
		_fail("Missing MONSTER ROUTER: CRUSH WINDUP module.")
		return {}
	return main._selected_component("hero", "module", index)


func _fighter_with_binding(part: Dictionary) -> Array:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [0],
		"module_action_profile": "swing_180",
		"module_part": part.duplicate(true),
		"joint_drive_allocation_by_node": {"0": 120.0},
		"allocated_limb_momentum_by_node": {"0": 120.0},
	}
	fighter.setup_unit({
		"unit_name": "Crush Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 45.0,
			"move_speed": 2.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{
				"node_index": 0,
				"part_index": 0,
				"part_kind": "limb_muscle",
				"name": "Probe Maul Arm",
				"a_local": Vector2.ZERO,
				"b_local": Vector2(0.85, 0.0),
				"axis_local": Vector2.RIGHT,
				"radius": 0.11,
				"damage_type": "blunt",
				"material_class": "weapon",
				"contact_damage_mult": 0.24,
				"damage_coeff": 0.24,
				"runtime_topology": true,
			}],
			"runtime_module_bindings": [binding],
		},
	})
	fighter.deploy(0.0, 0.0)
	return [fighter, binding]


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var part := _module_part(main)
	var whiff_pair := _fighter_with_binding(part)
	var whiff_fighter = whiff_pair[0]
	var whiff_binding: Dictionary = whiff_pair[1]
	var whiff_event: Dictionary = whiff_fighter.begin_runtime_module_action("normal", whiff_binding, Vector2.RIGHT)
	if whiff_event.is_empty():
		_fail("CRUSH WINDUP failed to start whiff sample.")
	whiff_fighter._tick_runtime_module_actions(99.0)
	if String(whiff_fighter.get_meta("last_crush_windup_result", "")) != "whiff":
		_fail("CRUSH WINDUP did not record whiff result.")
	if float(whiff_fighter.get_meta("last_crush_whiff_recovery", 0.0)) <= 0.0:
		_fail("CRUSH WINDUP whiff did not add recovery.")

	var hit_pair := _fighter_with_binding(part)
	var hit_fighter = hit_pair[0]
	var hit_binding: Dictionary = hit_pair[1]
	var hit_event: Dictionary = hit_fighter.begin_runtime_module_action("normal", hit_binding, Vector2.RIGHT)
	if hit_event.is_empty():
		_fail("CRUSH WINDUP failed to start hit sample.")
	hit_fighter.mark_runtime_module_variant_hit(1, "crush_windup")
	hit_fighter._tick_runtime_module_actions(99.0)
	if String(hit_fighter.get_meta("last_crush_windup_result", "")) != "hit":
		_fail("CRUSH WINDUP hit-confirmed action should not be treated as whiff.")
	if float(hit_fighter.get_meta("last_crush_whiff_recovery", 0.0)) > 0.0:
		_fail("CRUSH WINDUP hit-confirmed action should not add whiff recovery.")
	print("CRUSH_WINDUP_WHIFF_RECOVERY_PROBE ok whiff_extra=%.3f" % float(whiff_fighter.get_meta("last_crush_whiff_recovery", 0.0)))
	quit()
