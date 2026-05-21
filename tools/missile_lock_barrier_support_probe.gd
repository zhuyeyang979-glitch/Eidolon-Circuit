extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(name: String, owner_id: int, role_key: String, ring: float, lane: float, stats: Dictionary) -> Node:
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
	var attacker = _make_unit("MISSILE_USER", 1, "hero", 5.0, 0.0, {})
	var support = _make_unit("REPAIR_STATION", 2, "barrier", 6.8, 0.0, {"is_repair_station": true})
	var attack = _make_unit("BARRAGE_TILE", 2, "barrier", 6.0, 0.0, {"is_barrage_emitter": true})
	main.all_units = [attacker, support, attack]
	main.active_units = {1: {"hero": attacker, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": support, "puppet": [attack]}}
	var event := {"direction": Vector2.RIGHT, "range": 3.4, "missile_lock_range": 3.4, "missile_lock_cone_degrees": 70.0, "missile_lock_priority": "screen_hero_first"}
	if main._acquire_missile_lock_target(attacker, event) != support:
		_fail("Barrier support should outrank barrier attack under screen_hero_first.")
	print("MISSILE_LOCK_BARRIER_SUPPORT_PROBE ok")
	quit()
