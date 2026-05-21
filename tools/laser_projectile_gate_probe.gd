extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_runtime_unit() -> Node:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "LASER_GATE_PROBE",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 40.0,
			"health": 100,
			"runtime_topology_segments": [{
				"node_index": 0,
				"part_kind": "muscle",
				"name": "Probe Laser",
				"shape": "polygon",
				"polygon_local": [Vector2(-0.16, -0.04), Vector2(0.16, -0.04), Vector2(0.16, 0.04), Vector2(-0.16, 0.04)],
				"radius": 0.04,
				"damage_type": "laser",
				"projectile_damage_type": "laser",
				"projectile": true,
				"projectile_only": true,
				"material_class": "gun",
				"gun_kind": "laser_gun",
				"ammo_kind": "laser",
				"terminal_weapon_kind": "ranged",
			}],
			"runtime_module_bindings": [],
		},
	})
	fighter.deploy(4.0, 0.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var attacker = _make_runtime_unit()
	main.active_units = {1: {"hero": attacker, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	var laser_event := {
		"module_action_profile": "laser_beam_activate",
		"gun_activation": true,
		"projectile": true,
		"projectile_only": true,
		"muscle_node": 0,
		"collision_group": {
			"projectile": true,
			"material_class": "gun",
			"shape": "laser_gun",
		},
		"damage_type": "laser",
		"projectile_damage_type": "laser",
		"projectile_style": "beam",
		"projectile_behavior": "laser",
		"laser_telegraph_ready": true,
	}
	if not main._event_is_explicit_gun_activation(laser_event):
		_fail("laser_beam_activate should be an explicit gun activation profile.")
	main._resolve_attack(attacker, laser_event)
	if not bool(laser_event.get("projectile", false)):
		_fail("Explicit laser gun activation should retain projectile fields.")
	var fake_melee := laser_event.duplicate(true)
	fake_melee["module_action_profile"] = "two_link_forward_snap"
	fake_melee["runtime_binding"] = true
	main._resolve_attack(attacker, fake_melee)
	if bool(fake_melee.get("projectile", true)):
		_fail("Non-gun runtime event should still lose projectile fields.")
	print("LASER_PROJECTILE_GATE_PROBE ok")
	quit()

