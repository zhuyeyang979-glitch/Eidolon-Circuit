extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, owner: int, role_key: String, name: String, ring: float, lane: float, stats_extra: Dictionary = {}):
	var stats := {
		"health": 100,
		"max_health": 100,
		"mass": 20.0,
		"radius": 0.14,
		"teamedit_runtime_topology": false,
	}
	for key in stats_extra.keys():
		stats[key] = stats_extra[key]
	var unit = main._create_unit(owner, role_key, stats, name, ring, lane)
	main._assign_unit_role(unit, role_key)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	var puppet = _spawn_unit(main, 1, "puppet", "SIGHT PUPPET", 5.0, 0.0, {"source_target_policy": "hero_low_hp_ranged"})
	var target = _spawn_unit(main, 2, "hero", "SIGHT TARGET", 6.4, 0.0)
	main.active_units = {1: {"hero": null, "barrier": null, "puppet": [puppet]}, 2: {"hero": target, "barrier": null, "puppet": []}}
	var clear_score := main._source_target_score(puppet, target, 1, "hero_low_hp_ranged")
	var wall = _spawn_unit(main, 2, "barrier", "SIGHT WALL", 5.7, 0.0, {"is_cage_wall": true, "material_class": "barrier_wall", "radius": 0.18})
	main.active_units[2]["barrier"] = wall
	var blocked_score := main._source_target_score(puppet, target, 1, "hero_low_hp_ranged")
	if blocked_score >= clear_score - 60.0:
		_fail("AI sight score should strongly penalize map occlusion: clear=%.2f blocked=%.2f" % [clear_score, blocked_score])
	if main._map_line_of_sight_clear(puppet, target, {"direction": Vector2.RIGHT, "range": 1.6, "lane_range": 0.08, "ai_line_of_sight": true}):
		_fail("AI line of sight helper should report the wall as occluding.")
	print("MAP_OCCLUSION_AI_SIGHT_PROBE ok clear=%.2f blocked=%.2f" % [clear_score, blocked_score])
	quit()
