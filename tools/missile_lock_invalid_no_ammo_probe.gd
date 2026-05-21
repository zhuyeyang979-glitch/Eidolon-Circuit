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
	attacker.setup_unit({"unit_name": "MISSILE_USER", "owner_id": 1, "role": "hero", "stats": {"mass": 24.0, "health": 100, "radius": 0.16, "ammo_capacity": {"explosive": 3}}})
	attacker.deploy(5.0, 0.0)
	main.unit_set_ammo(attacker, "explosive", 3)
	main.all_units = [attacker]
	main.active_units = {1: {"hero": attacker, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	var event := {"projectile": true, "projectile_only": true, "gun_activation": true, "module_action_profile": "missile_lock_activate", "muscle_node": 0, "collision_group": {"projectile": true, "projectile_only": true, "material_class": "missile_launcher", "shape": "missile_rack"}, "gun_kind": "missile_launcher", "ammo_kind": "explosive", "projectile_style": "missile", "projectile_behavior": "explosive", "travel_path": "homing", "direction": Vector2.RIGHT, "range": 3.4, "lane_range": 0.11}
	var ammo_before := main._current_ammo(attacker, "explosive")
	main._queue_missile_projectile(attacker, event)
	if main._current_ammo(attacker, "explosive") != ammo_before:
		_fail("No-lock missile queue helper should not consume ammo by itself.")
	if main.pending_missile_projectiles.size() != 0:
		_fail("No-lock missile should not queue a projectile.")
	print("MISSILE_LOCK_INVALID_NO_AMMO_PROBE ok")
	quit()
