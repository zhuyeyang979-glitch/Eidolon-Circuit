extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")

const SAMPLES := {
	"KINETIC BULLET GUN": ["gun_activate", "sniper", "bullet", "true_bullet"],
	"AUTOCANNON TURRET": ["rifle_burst_activate", "rifle", "bullet", "bullet_hell"],
	"CAUSTIC SPRAY GUN": ["gun_activate", "sprayer", "chemical", "spray"],
	"LASER EMITTER GUN": ["laser_beam_activate", "laser_gun", "laser", "beam"],
	"红线跳爆榴弹枪 / REDLINE HOPPER GRENADE LAUNCHER": ["grenade_arc_activate", "grenade_launcher", "explosive", "explosive"],
	"WEB SILK PISTOL": ["web_tether_activate", "web_gun", "web", "web"],
}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part(main, name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", "muscle", name)
	if index < 0:
		for i in range(main._catalog_for("hero", "muscle").size()):
			var candidate: Dictionary = main._selected_component("hero", "muscle", i)
			if String(candidate.get("name", "")).to_upper().find(name.to_upper()) >= 0:
				index = i
				break
	if index < 0:
		_fail("Missing ranged weapon: %s" % name)
		return {}
	return main._selected_component("hero", "muscle", index)


func _segment_from_part(part: Dictionary) -> Dictionary:
	var segment := part.duplicate(true)
	segment["node_index"] = 0
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
	segment["momentum_min"] = 40.0
	segment["momentum_max"] = 120.0
	segment["allocated_limb_momentum"] = 80.0
	return segment


func _event_for(main, part: Dictionary, profile: String) -> Dictionary:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [0],
		"module_action_profile": profile,
		"module_part": {
			"name": profile,
			"module_action_profile": profile,
			"module_target_kind": "gun_terminal",
		},
		"joint_drive_allocation_by_node": {"0": 80.0},
		"allocated_limb_momentum_by_node": {"0": 80.0},
	}
	fighter.setup_unit({
		"unit_name": String(part.get("name", "Probe Gun")),
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
	main.gun_activation_state[1] = {"binding": binding, "aim_direction": Vector2.RIGHT}
	var event: Dictionary = main._runtime_gun_activation_event_for(1)
	main.gun_activation_state.erase(1)
	fighter.queue_free()
	return event


func _assert_sample(main, name: String, expected: Array) -> void:
	var profile := String(expected[0])
	var gun_kind := String(expected[1])
	var ammo_kind := String(expected[2])
	var style := String(expected[3])
	var part := _part(main, name)
	if part.is_empty():
		return
	if main._part_is_catalog_frozen("muscle", part):
		_fail("%s should be live before fire probe." % name)
	var event := _event_for(main, part, profile)
	if event.is_empty():
		_fail("%s did not create a runtime gun activation event." % name)
	if String(event.get("module_action_profile", "")) != profile:
		_fail("%s event profile expected %s, got %s." % [name, profile, String(event.get("module_action_profile", ""))])
	if String(event.get("gun_kind", "")) != gun_kind or String(event.get("ammo_kind", "")) != ammo_kind:
		_fail("%s event gun/ammo expected %s/%s, got %s/%s." % [name, gun_kind, ammo_kind, String(event.get("gun_kind", "")), String(event.get("ammo_kind", ""))])
	if not bool(event.get("projectile", false)):
		_fail("%s event is not projectile." % name)
	if String(event.get("projectile_style", "")) != style:
		_fail("%s style expected %s, got %s." % [name, style, String(event.get("projectile_style", ""))])
	if float(event.get("projectile_momentum", 0.0)) <= 0.0:
		_fail("%s event missing projectile momentum." % name)
	if not bool(event.get("non_damage", false)) and float(event.get("gun_projectile_damage_mult", 0.0)) <= 0.0:
		_fail("%s event missing damage multiplier." % name)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for name in SAMPLES.keys():
		_assert_sample(main, String(name), Array(SAMPLES[name]))
	print("BACKFILLED_RANGED_WEAPON_FIRE_PROBE ok samples=%d" % SAMPLES.size())
	quit()
