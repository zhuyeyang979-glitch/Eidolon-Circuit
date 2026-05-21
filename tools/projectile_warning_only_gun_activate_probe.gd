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
		"unit_name": "PROJECTILE_WARNING_PROBE",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 40.0,
			"health": 100,
			"runtime_topology_segments": [{
				"node_index": 0,
				"part_kind": "torso",
				"name": "Probe Torso",
				"shape": "polygon",
				"polygon_local": [Vector2(-0.16, -0.1), Vector2(0.16, -0.1), Vector2(0.16, 0.1), Vector2(-0.16, 0.1)],
				"radius": 0.1,
				"damage_type": "blunt",
				"material_class": "metal",
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
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": null, "barrier": null, "puppet": []},
	}
	var gun_event := {
		"module_action_profile": "gun_activate",
		"gun_activation": true,
		"projectile": true,
		"projectile_only": true,
		"muscle_node": 0,
	}
	main.battle_message = ""
	main.battle_message_timer = 0.0
	main._resolve_attack(attacker, gun_event)
	var gun_message := String(main.battle_message)
	if not (gun_message.contains("投射物") or gun_message.contains("Projectile requires")):
		_fail("Invalid Gun Activate projectile did not show the gun-source warning. message='%s'" % gun_message)

	var melee_event := {
		"module_action_profile": "two_link_forward_snap",
		"runtime_binding": true,
		"projectile": true,
		"projectile_only": true,
		"projectile_style": "missile",
		"projectile_behavior": "homing",
		"is_homing_launcher": true,
		"homing_accuracy": 0.57,
	}
	main.battle_message = ""
	main.battle_message_timer = 0.0
	main._resolve_attack(attacker, melee_event)
	var melee_message := String(main.battle_message)
	if melee_message.contains("投射物") or melee_message.contains("Projectile requires"):
		_fail("Non-gun runtime melee showed projectile warning. message='%s'" % melee_message)
	if bool(melee_event.get("projectile", true)):
		_fail("Non-gun runtime melee event was not normalized to projectile=false.")
	print("PROJECTILE_WARNING_ONLY_GUN_ACTIVATE_PROBE gun='%s' melee='%s'" % [gun_message, melee_message])
	quit()
