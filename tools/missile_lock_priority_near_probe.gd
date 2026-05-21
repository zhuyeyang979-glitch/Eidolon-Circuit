extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(name: String, owner_id: int, role_key: String, ring: float, lane: float) -> Node:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": name, "owner_id": owner_id, "role": role_key, "stats": {"mass": 20.0, "health": 100, "radius": 0.16}})
	fighter.deploy(ring, lane)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var attacker = _make_unit("MISSILE_USER", 1, "hero", 5.0, 0.0)
	var near = _make_unit("NEAR_TARGET", 2, "puppet", 6.0, 0.0)
	var far = _make_unit("FAR_TARGET", 2, "puppet", 7.4, 0.0)
	main.all_units = [attacker, near, far]
	main.active_units = {1: {"hero": attacker, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": [near, far]}}
	var event := {"direction": Vector2.RIGHT, "range": 3.4, "missile_lock_range": 3.4, "missile_lock_cone_degrees": 60.0, "missile_lock_priority": "near_first"}
	if main._acquire_missile_lock_target(attacker, event) != near:
		_fail("near_first should select the closest legal target.")
	print("MISSILE_LOCK_PRIORITY_NEAR_PROBE ok")
	quit()
