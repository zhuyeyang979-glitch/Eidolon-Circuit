extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var attacker = FighterScene.new()
	root.add_child(attacker)
	attacker._ready()
	attacker.setup_unit({"unit_name": "MISSILE_USER", "owner_id": 1, "role": "hero", "stats": {"mass": 30.0, "health": 100, "radius": 0.16, "heat_capacity": 100.0, "ammo_capacity": {"explosive": 3}}})
	attacker.deploy(5.0, 0.0)
	var target = FighterScene.new()
	root.add_child(target)
	target._ready()
	target.setup_unit({"unit_name": "MISSILE_TARGET", "owner_id": 2, "role": "hero", "stats": {"mass": 20.0, "health": 100, "radius": 0.16}})
	target.deploy(6.2, 0.0)
	main.all_units = [attacker, target]
	main.active_units = {1: {"hero": attacker, "barrier": null, "puppet": []}, 2: {"hero": target, "barrier": null, "puppet": []}}
	var event := {"projectile": true, "projectile_only": true, "gun_activation": true, "module_action_profile": "missile_lock_activate", "muscle_node": 0, "collision_group": {"projectile": true, "projectile_only": true, "material_class": "missile_launcher", "shape": "missile_rack"}, "gun_kind": "missile_launcher", "ammo_kind": "explosive", "projectile_style": "missile", "projectile_behavior": "explosive", "travel_path": "homing", "direction": Vector2.RIGHT, "range": 3.4, "lane_range": 0.11, "locked_target": target, "normal_heat": 34.0}
	var ammo_before := main._current_ammo(attacker, "explosive")
	main._runtime_gun_activation_fire_once(attacker, event)
	if main._current_ammo(attacker, "explosive") != ammo_before - 1:
		_fail("Missile fire should consume one explosive ammo.")
	if float(attacker.heat) < 33.9:
		_fail("Missile fire should add normal heat.")
	print("MISSILE_AMMO_HEAT_PROBE ok ammo=%d heat=%.1f" % [main._current_ammo(attacker, "explosive"), float(attacker.heat)])
	quit()
