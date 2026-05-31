extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _puppet_bp(source_index: int) -> Dictionary:
	return {
		"name": "Piercing Retinue Probe",
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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var source_index := main._component_index_by_name("puppet", "special", "CODE: PIERCING RETINUE", -1)
	if source_index < 0:
		_fail("CODE: PIERCING RETINUE should exist in puppet special catalog.")
		return
	var stats: Dictionary = main._compute_unit_stats(1, "puppet", 0, _puppet_bp(source_index))
	if String(stats.get("source_target_policy", "")) != "protect_hero":
		_fail("Piercing retinue should protect the hero.")
		return
	if String(stats.get("source_attack_preference", "")) != "melee_first":
		_fail("Piercing retinue should prefer melee modules.")
		return
	if int(stats.get("group_count", 0)) != 3 or int(stats.get("module_sequence_limit", 0)) != 4:
		_fail("Piercing retinue should be a three-puppet, four-step source code.")
		return
	var rules: Dictionary = stats.get("source_rules", {})
	if String(Dictionary(rules.get("enemy_close", {})).get("move", "")) != "intercept":
		_fail("Piercing retinue should intercept close threats.")
		return
	if String(Dictionary(rules.get("enemy_far", {})).get("move", "")) != "orbit":
		_fail("Piercing retinue should orbit while waiting for far threats.")
		return
	var retinue = main._create_unit(1, "puppet", stats, "RETINUE", 4.0, 0.0)
	var own_hero_stats: Dictionary = main._compute_unit_stats(1, "hero", 0)
	var own_hero = main._create_unit(1, "hero", own_hero_stats, "OWN HERO", 4.1, 0.0)
	var far_hero_stats: Dictionary = main._compute_unit_stats(2, "hero", 0)
	var far_hero = main._create_unit(2, "hero", far_hero_stats, "FAR HERO", 6.8, 0.0)
	var close_threat = main._create_unit(2, "puppet", stats, "CLOSE THREAT", 4.6, 0.0)
	main.active_units[1]["hero"] = own_hero
	main.active_units[1]["puppet"] = [retinue]
	main.active_units[2]["hero"] = far_hero
	main.active_units[2]["puppet"] = [close_threat]
	var target = main._source_target_for_puppet(retinue, 1)
	if target != close_threat:
		_fail("Piercing retinue should override to close hero threat.")
		return
	print("PIERCING_RETINUE_SOURCE_CODE_PROBE ok index=%d" % source_index)
	quit()
