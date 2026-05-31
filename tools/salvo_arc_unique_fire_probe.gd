extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _module_part(main) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", "module", "SALVO ROUTER: EXPLOSIVE ARC")
	if index < 0:
		_fail("Missing SALVO ROUTER: EXPLOSIVE ARC module.")
		return {}
	return main._selected_component("hero", "module", index)


func _grenade_part(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("gun_kind", main._gun_kind_for_data(part))) == "grenade_launcher" and String(part.get("ammo_kind", main._ammo_kind_for_data(part))) == "explosive":
			return part
	_fail("Missing grenade/explosive gun terminal.")
	return {}


func _segment_from_part(part: Dictionary) -> Dictionary:
	var segment := part.duplicate(true)
	segment["node_index"] = 0
	segment["part_index"] = 0
	segment["part_kind"] = "muscle"
	segment["a_local"] = Vector2.ZERO
	segment["b_local"] = Vector2(maxf(0.18, float(part.get("length", 0.5))), 0.0)
	segment["axis_local"] = Vector2.RIGHT
	segment["radius"] = maxf(0.02, float(part.get("radius", 0.05)))
	segment["terminal_weapon_kind"] = "ranged"
	segment["gun_kind"] = "grenade_launcher"
	segment["ammo_kind"] = "explosive"
	segment["projectile_behavior"] = "explosive"
	segment["projectile_style"] = "explosive"
	segment["travel_path"] = "arc_u"
	segment["projectile"] = true
	segment["projectile_only"] = true
	segment["joint_output_momentum_base"] = 80.0
	segment["joint_drive_allocation"] = 80.0
	segment["momentum_min"] = 40.0
	segment["momentum_max"] = 120.0
	segment["allocated_limb_momentum"] = 80.0
	return segment


func _event_for(main, gun_part: Dictionary, module_part: Dictionary, hold_time: float) -> Dictionary:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [0],
		"module_action_profile": "grenade_arc_activate",
		"module_part": module_part.duplicate(true),
		"joint_drive_allocation_by_node": {"0": 80.0},
		"allocated_limb_momentum_by_node": {"0": 80.0},
	}
	fighter.setup_unit({
		"unit_name": "Salvo Arc Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 32.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [_segment_from_part(gun_part)],
			"runtime_module_bindings": [binding],
		},
	})
	fighter.deploy(0.0, 0.0)
	main.active_units = {1: {"hero": fighter, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	main.gun_activation_state[1] = {"binding": binding, "aim_direction": Vector2.RIGHT, "hold_time": hold_time}
	var event: Dictionary = main._runtime_gun_activation_event_for(1)
	main.gun_activation_state.erase(1)
	fighter.queue_free()
	return event


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var module_part := _module_part(main)
	var gun_part := _grenade_part(main)
	if not main._gun_activation_profile_supports_kind("grenade_arc_activate", "grenade_launcher", "explosive"):
		_fail("grenade_arc_activate should support grenade_launcher/explosive.")
	if main._gun_activation_profile_supports_kind("grenade_arc_activate", "rifle", "bullet"):
		_fail("grenade_arc_activate should reject rifle/bullet.")
	if String(module_part.get("module_variant_key", "")) != "explosive_arc_salvo":
		_fail("Salvo module missing explosive_arc_salvo variant.")
	var tap_event := _event_for(main, gun_part, module_part, 0.0)
	var hold_event := _event_for(main, gun_part, module_part, float(module_part.get("salvo_hold_range_seconds", 0.75)))
	if tap_event.is_empty() or hold_event.is_empty():
		_fail("Salvo did not create grenade arc events.")
	if String(tap_event.get("module_variant_key", "")) != "explosive_arc_salvo":
		_fail("Salvo event missing variant key.")
	if not bool(tap_event.get("salvo_landing_marker", false)):
		_fail("Salvo event missing landing marker.")
	if float(hold_event.get("range", 0.0)) <= float(tap_event.get("range", 0.0)):
		_fail("Salvo hold range should increase. tap=%.2f hold=%.2f" % [float(tap_event.get("range", 0.0)), float(hold_event.get("range", 0.0))])
	if String(hold_event.get("travel_path", "")) != "arc_u" or String(hold_event.get("projectile_style", "")) != "explosive":
		_fail("Salvo event should stay arc_u/explosive.")
	print("SALVO_ARC_UNIQUE_FIRE_PROBE ok tap=%.2f hold=%.2f" % [float(tap_event.get("range", 0.0)), float(hold_event.get("range", 0.0))])
	quit()
