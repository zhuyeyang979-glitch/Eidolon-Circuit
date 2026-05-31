extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(name: String, owner_id: int, ring: float) -> Node:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": name, "owner_id": owner_id, "role": "hero", "stats": {"mass": 24.0, "health": 100, "radius": 0.16, "ammo_capacity": {"explosive": 3}}})
	fighter.deploy(ring, 0.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var attacker = _make_unit("MISSILE_USER", 1, 5.0)
	var target = _make_unit("MISSILE_TARGET", 2, 6.3)
	main.all_units = [attacker, target]
	main.active_units = {1: {"hero": attacker, "barrier": null, "puppet": []}, 2: {"hero": target, "barrier": null, "puppet": []}}
	var event := {"projectile": true, "projectile_only": true, "gun_activation": true, "module_action_profile": "missile_lock_activate", "muscle_node": 0, "collision_group": {"projectile": true, "projectile_only": true, "material_class": "missile_launcher", "shape": "missile_rack"}, "gun_kind": "missile_launcher", "ammo_kind": "explosive", "projectile_style": "missile", "projectile_behavior": "explosive", "travel_path": "homing", "direction": Vector2.RIGHT, "range": 3.4, "lane_range": 0.11, "locked_target": target, "missile_occlusion_grace": 0.28}
	main._runtime_gun_activation_fire_once(attacker, event)
	if main.pending_missile_projectiles.size() != 1:
		_fail("Missile fire should queue one visible homing projectile.")
	var shot: Dictionary = main.pending_missile_projectiles[0]
	if shot.get("target", null) != target:
		_fail("Queued missile should retain its locked target.")
	print("MISSILE_LOCK_RUNTIME_FIRE_PROBE ok")
	quit()
