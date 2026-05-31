extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_hero(main, name: String, owner_id: int, ring: float, heat: float, overheated: bool = false):
	var stats: Dictionary = main._compute_unit_stats(owner_id, "hero", 0)
	stats["health"] = 100
	stats["heat_capacity"] = 100.0
	var unit = main._create_unit(owner_id, "hero", stats, name, ring, 0.0)
	unit.heat = heat
	unit.overheated = overheated
	return unit


func _make_puppet(main, name: String, owner_id: int, ring: float, source_index: int):
	var blueprint := {
		"name": name,
		"archetype": "custom",
		"special": source_index,
		"joint": 16,
		"limb_muscle": 0,
		"muscle": 95,
		"booster": 0,
		"engine": 0,
		"cooling": 5,
		"module": 0,
	}
	var stats: Dictionary = main._compute_unit_stats(owner_id, "puppet", 0, blueprint)
	return main._create_unit(owner_id, "puppet", stats, name, ring, 0.0)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var source_index := main._component_index_by_name("puppet", "special", "CODE: THERMAL PIT CREW", -1)
	if source_index < 0:
		_fail("CODE: THERMAL PIT CREW should exist before heat-pressure policy test.")
		return
	var puppet = _make_puppet(main, "PIT CREW", 1, 4.0, source_index)
	var own_hero = _make_hero(main, "OWN HERO", 1, 3.5, 0.0)
	var cold_close = _make_hero(main, "COLD MID HERO", 2, 5.0, 0.0)
	var hot_far = _make_hero(main, "HOT FAR HERO", 2, 5.8, 82.0)
	main.active_units[1]["hero"] = own_hero
	main.active_units[1]["puppet"] = [puppet]
	main.active_units[2]["hero"] = cold_close
	main.active_units[2]["puppet"] = [hot_far]
	var cold_score := main._source_target_score(puppet, cold_close, 1, "heat_pressure_first")
	var hot_score := main._source_target_score(puppet, hot_far, 1, "heat_pressure_first")
	var target = main._source_target_for_puppet(puppet, 1)
	if target != hot_far:
		_fail("heat_pressure_first should prefer a far high-heat hero over a closer cold hero. got=%s cold=%.2f hot=%.2f policy=%s heat=%.2f" % [target.unit_name if target != null else "NONE", cold_score, hot_score, String(puppet.stats.get("source_target_policy", "")), float(hot_far.heat_ratio())])
		return
	hot_far.heat = 10.0
	cold_close.heat = 0.0
	cold_close.overheated = true
	target = main._source_target_for_puppet(puppet, 1)
	if target != cold_close:
		_fail("heat_pressure_first should prefer an overheated target.")
		return
	hot_far.heat = 0.0
	cold_close.heat = 0.0
	cold_close.overheated = false
	target = main._source_target_for_puppet(puppet, 1)
	if target != cold_close:
		_fail("heat_pressure_first should fall back to normal hero/distance scoring without heat.")
		return
	print("SOURCE_HEAT_PRESSURE_POLICY_PROBE ok")
	quit()
