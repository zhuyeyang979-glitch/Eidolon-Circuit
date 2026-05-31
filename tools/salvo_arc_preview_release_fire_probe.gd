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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main.effects_root == null:
		main.effects_root = Node2D.new()
		root.add_child(main.effects_root)
	var module_part := _module_part(main)
	var gun_part := _grenade_part(main)
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
		"unit_name": "Salvo Release Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 32.0,
			"ammo_capacity": {"explosive": 3},
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [_segment_from_part(gun_part)],
			"runtime_module_bindings": [binding],
		},
	})
	fighter.deploy(0.0, 0.0)
	main.active_units = {1: {"hero": fighter, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	main.unit_set_ammo(fighter, "explosive", 3)
	main.gun_activation_state[1] = {
		"binding": binding,
		"aim_direction": Vector2.RIGHT,
		"hold_time": float(module_part.get("salvo_hold_range_seconds", 0.75)),
		"activation_semantic": "hold_grenade_arc",
		"action_name": "probe_salvo",
	}
	var preview_event: Dictionary = main._runtime_gun_activation_event_for(1)
	if preview_event.is_empty() or String(preview_event.get("module_variant_key", "")) != "explosive_arc_salvo":
		_fail("SALVO ARC did not build explosive_arc_salvo preview event.")
	if not main._event_is_explicit_gun_activation(preview_event):
		_fail("SALVO ARC preview event should stay in explicit projectile gate.")
	if not main._projectile_event_has_gun_source(preview_event):
		_fail("SALVO ARC preview event should carry a gun source collision group.")
	main._update_salvo_landing_preview(1, fighter, preview_event)
	if not main.salvo_landing_preview_effects.has(1):
		_fail("SALVO ARC did not create landing preview effect.")
	if main._current_ammo(fighter, "explosive") != 3:
		_fail("SALVO ARC preview should not consume ammo.")
	main._release_runtime_gun_activation(1)
	if main._current_ammo(fighter, "explosive") != 2:
		_fail("SALVO ARC release should fire exactly one shell.")
	if main.salvo_landing_preview_effects.has(1):
		_fail("SALVO ARC release should clear landing preview effect.")
	print("SALVO_ARC_PREVIEW_RELEASE_FIRE_PROBE ok ammo=%d" % main._current_ammo(fighter, "explosive"))
	quit()
