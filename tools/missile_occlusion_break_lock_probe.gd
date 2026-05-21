extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(name: String, owner_id: int, role_key: String, ring: float, lane: float, stats: Dictionary = {}) -> Node:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	var unit_stats := {"mass": 20.0, "health": 100, "radius": 0.16}
	for key in stats.keys():
		unit_stats[key] = stats[key]
	fighter.setup_unit({"unit_name": name, "owner_id": owner_id, "role": role_key, "stats": unit_stats})
	fighter.deploy(ring, lane)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var attacker = _make_unit("MISSILE_USER", 1, "hero", 5.0, 0.0, {"ammo_capacity": {"explosive": 3}})
	var target = _make_unit("FAST_TARGET", 2, "hero", 7.0, 0.0)
	var wall = _make_unit("CAGE_WALL", 2, "barrier", 6.0, 0.0, {"is_cage_wall": true, "shield_radius": 0.7, "shield_lane_width": 0.3})
	main.all_units = [attacker, target, wall]
	main.active_units = {1: {"hero": attacker, "barrier": null, "puppet": []}, 2: {"hero": target, "barrier": wall, "puppet": []}}
	var event := {"projectile": true, "projectile_only": true, "gun_activation": true, "module_action_profile": "missile_lock_activate", "muscle_node": 0, "collision_group": {"projectile": true, "projectile_only": true, "material_class": "missile_launcher", "shape": "missile_rack"}, "gun_kind": "missile_launcher", "ammo_kind": "explosive", "projectile_style": "missile", "projectile_behavior": "explosive", "travel_path": "homing", "direction": Vector2.RIGHT, "range": 3.4, "lane_range": 0.11, "locked_target": target, "missile_occlusion_grace": 0.28}
	if not main._missile_target_occluded(attacker, target, event):
		_fail("Cage wall between attacker and target should occlude missile lock.")
	main._queue_missile_projectile(attacker, event)
	for i in range(24):
		main._update_missile_projectiles(1.0 / 60.0)
	if main.pending_missile_projectiles.size() != 1:
		_fail("Missile should still be pending during occlusion test.")
	var shot: Dictionary = main.pending_missile_projectiles[0]
	if shot.get("target", null) != null:
		_fail("Missile should drop its target after occlusion grace.")
	print("MISSILE_OCCLUSION_BREAK_LOCK_PROBE ok")
	quit()
