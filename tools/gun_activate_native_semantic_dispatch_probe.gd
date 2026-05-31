extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")

const FIREARMS := [
	{"gun_kind": "sniper", "ammo_kind": "bullet", "profile": "gun_activate", "semantic": "release_lock", "style": "true_bullet"},
	{"gun_kind": "sprayer", "ammo_kind": "chemical", "profile": "gun_activate", "semantic": "hold_stream", "style": "spray"},
	{"gun_kind": "rifle", "ammo_kind": "bullet", "profile": "rifle_burst_activate", "semantic": "hold_burst", "style": "bullet_hell"},
	{"gun_kind": "laser_gun", "ammo_kind": "laser", "profile": "laser_beam_activate", "semantic": "hold_beam", "style": "beam"},
	{"gun_kind": "grenade_launcher", "ammo_kind": "explosive", "profile": "grenade_arc_activate", "semantic": "hold_grenade_arc", "style": "explosive"},
	{"gun_kind": "missile_launcher", "ammo_kind": "explosive", "profile": "missile_lock_activate", "semantic": "release_missile_lock", "style": "missile"},
	{"gun_kind": "web_gun", "ammo_kind": "web", "profile": "web_tether_activate", "semantic": "release_web", "style": "web"},
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _generic_module(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == "gun_activate":
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
	segment["projectile"] = true
	segment["projectile_only"] = true
	segment["joint_output_momentum_base"] = 80.0
	segment["joint_drive_allocation"] = 80.0
	segment["momentum_min"] = 20.0
	segment["momentum_max"] = 120.0
	segment["allocated_limb_momentum"] = 80.0
	return segment


func _event_for(main, module_part: Dictionary, firearm: Dictionary) -> Dictionary:
	var gun_kind := String(firearm.get("gun_kind", ""))
	var ammo_kind := String(firearm.get("ammo_kind", ""))
	var part := _gun_part(main, gun_kind, ammo_kind)
	if part.is_empty():
		_fail("Missing live firearm for event dispatch: %s/%s." % [gun_kind, ammo_kind])
		return {}
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [0],
		"module_action_profile": "gun_activate",
		"module_part": module_part.duplicate(true),
		"joint_drive_allocation_by_node": {"0": 80.0},
		"allocated_limb_momentum_by_node": {"0": 80.0},
	}
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Generic Gun Activate Dispatch",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 32.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [_segment_from_part(part)],
			"runtime_module_bindings": [binding],
		},
	})
	fighter.deploy(0.0, 0.0)
	main.active_units = {1: {"hero": fighter, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	main._start_runtime_gun_activation(1, "p1_", 0, "probe_fire", binding)
	var state: Dictionary = main.gun_activation_state.get(1, {})
	if String(state.get("activation_semantic", "")) != String(firearm.get("semantic", "")):
		_fail("Generic Gun Activate semantic mismatch for %s: %s." % [gun_kind, String(state.get("activation_semantic", ""))])
	var event: Dictionary = main._runtime_gun_activation_event_for(1)
	main.gun_activation_state.erase(1)
	fighter.queue_free()
	return event


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var module_part := _generic_module(main)
	if module_part.is_empty():
		_fail("Generic Gun Activate module missing.")
		return
	for firearm in FIREARMS:
		var event := _event_for(main, module_part, firearm)
		if event.is_empty():
			_fail("Generic Gun Activate made no event for %s." % String(firearm.get("gun_kind", "")))
			return
		if String(event.get("module_action_profile", "")) != "gun_activate":
			_fail("Generic source profile was lost for %s." % String(firearm.get("gun_kind", "")))
		if String(event.get("effective_gun_activation_profile", "")) != String(firearm.get("profile", "")):
			_fail("Effective profile mismatch for %s: %s." % [String(firearm.get("gun_kind", "")), String(event.get("effective_gun_activation_profile", ""))])
		if String(event.get("projectile_style", "")) != String(firearm.get("style", "")):
			_fail("Projectile style mismatch for %s: %s." % [String(firearm.get("gun_kind", "")), String(event.get("projectile_style", ""))])
	print("GUN_ACTIVATE_NATIVE_SEMANTIC_DISPATCH_PROBE ok count=%d" % FIREARMS.size())
	quit()
