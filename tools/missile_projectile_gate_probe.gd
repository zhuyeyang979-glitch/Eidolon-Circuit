extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(name: String, owner_id: int) -> Node:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": name, "owner_id": owner_id, "role": "hero", "stats": {"teamedit_runtime_topology": true, "mass": 30.0, "health": 100, "radius": 0.16, "ammo_capacity": {"explosive": 3}}})
	fighter.deploy(5.0 if owner_id == 1 else 6.0, 0.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var attacker = _make_unit("MISSILE_USER", 1)
	var target = _make_unit("MISSILE_TARGET", 2)
	main.all_units = [attacker, target]
	main.active_units = {1: {"hero": attacker, "barrier": null, "puppet": []}, 2: {"hero": target, "barrier": null, "puppet": []}}
	var missile_event := {"projectile": true, "projectile_only": true, "gun_activation": true, "module_action_profile": "missile_lock_activate", "muscle_node": 0, "collision_group": {"projectile": true, "projectile_only": true, "material_class": "missile_launcher", "shape": "missile_rack"}, "gun_kind": "missile_launcher", "ammo_kind": "explosive", "projectile_style": "missile", "projectile_behavior": "explosive", "travel_path": "homing", "direction": Vector2.RIGHT, "range": 3.4, "lane_range": 0.11, "locked_target": target}
	if not main._event_is_explicit_gun_activation(missile_event):
		_fail("missile_lock_activate should be an explicit gun activation.")
	var fake_melee := missile_event.duplicate(true)
	fake_melee["module_action_profile"] = "blunt_hammer_windup_slam"
	main._resolve_attack(attacker, fake_melee)
	if bool(fake_melee.get("projectile", false)) or String(fake_melee.get("projectile_style", "")) != "":
		_fail("Non-gun missile-like melee event should have projectile fields cleared.")
	print("MISSILE_PROJECTILE_GATE_PROBE ok")
	quit()
