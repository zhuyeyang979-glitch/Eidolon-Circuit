extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _puppet_bp(source_index: int, unit_name: String) -> Dictionary:
	return {
		"name": unit_name,
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
	var source_indices := [14, 15, 16, 17, 18]
	for source_index in source_indices:
		var stats: Dictionary = main._compute_unit_stats(1, "puppet", 0, _puppet_bp(source_index, "Probe Source"))
		print("SOURCE_CODE %d %s bodies=%d ai=%s target=%s attack=%s close=%s keep=%.2f rules=%d" % [
			source_index,
			String(MainScene.SPECIAL_CATALOG["puppet"][source_index].get("name", "")),
			int(stats.get("group_count", 0)),
			String(stats.get("ai", "")),
			String(stats.get("source_target_policy", "")),
			String(stats.get("source_attack_preference", "")),
			String(stats.get("source_close_response", "")),
			float(stats.get("source_keep_range", 0.0)),
			Dictionary(stats.get("source_rules", {})).size(),
		])
		if int(stats.get("group_count", 1)) <= 1 or String(stats.get("ai", "direct")) == "direct":
			_fail("Source code index %d did not merge code stats." % source_index)

	var ranger_stats: Dictionary = main._compute_unit_stats(1, "puppet", 0, _puppet_bp(14, "Ranger Probe"))
	var ranger = main._create_unit(1, "puppet", ranger_stats, "RANGER", 4.0, 0.0)
	main.active_units[1]["puppet"] = [ranger]
	var own_hero_stats: Dictionary = main._compute_unit_stats(1, "hero", 0)
	main.active_units[1]["hero"] = main._create_unit(1, "hero", own_hero_stats, "OWN HERO", 3.5, 0.0)
	var enemy_hero_stats: Dictionary = main._compute_unit_stats(2, "hero", 0)
	var enemy_hero = main._create_unit(2, "hero", enemy_hero_stats, "ENEMY HERO", 5.0, 0.0)
	main.active_units[2]["hero"] = enemy_hero
	var enemy_puppet_stats := ranger_stats.duplicate(true)
	enemy_puppet_stats["health"] = 80
	var wounded_puppet = main._create_unit(2, "puppet", enemy_puppet_stats, "WOUNDED PUPPET", 6.1, 0.0)
	wounded_puppet.health = 12
	wounded_puppet.max_health = 80
	main.active_units[2]["puppet"] = [wounded_puppet]
	var ranger_target = main._source_target_for_puppet(ranger, 1)
	print("SOURCE_TARGET ranger_far=%s" % [ranger_target.unit_name if ranger_target != null else "NONE"])
	wounded_puppet.ring_pos = 4.45
	var ranger_close_target = main._source_target_for_puppet(ranger, 1)
	print("SOURCE_TARGET ranger_close=%s" % [ranger_close_target.unit_name if ranger_close_target != null else "NONE"])

	var execution_stats: Dictionary = main._compute_unit_stats(1, "puppet", 0, _puppet_bp(15, "Execution Probe"))
	var execution = main._create_unit(1, "puppet", execution_stats, "EXECUTION", 4.0, 0.0)
	main.active_units[1]["puppet"] = [execution]
	var execution_target = main._source_target_for_puppet(execution, 1)
	print("SOURCE_TARGET execution=%s" % [execution_target.unit_name if execution_target != null else "NONE"])

	var vanguard_stats: Dictionary = main._compute_unit_stats(1, "puppet", 0, _puppet_bp(18, "Vanguard Probe"))
	var vanguard = main._create_unit(1, "puppet", vanguard_stats, "VANGUARD", 4.0, 0.0)
	var ally_puppet = main._create_unit(1, "puppet", vanguard_stats, "ALLY PUPPET", 4.7, 0.0)
	main.active_units[1]["puppet"] = [vanguard, ally_puppet]
	var far_enemy_hero = main._create_unit(2, "hero", enemy_hero_stats, "FAR HERO", 7.4, 0.0)
	var group_threat = main._create_unit(2, "puppet", enemy_puppet_stats, "GROUP THREAT", 4.9, 0.02)
	group_threat.set_meta("projectile_signal", 1.0)
	main.active_units[2]["hero"] = far_enemy_hero
	main.active_units[2]["puppet"] = [group_threat]
	var vanguard_target = main._source_target_for_puppet(vanguard, 1)
	print("SOURCE_TARGET vanguard_cover=%s" % [vanguard_target.unit_name if vanguard_target != null else "NONE"])
	if failed:
		quit(1)
		return
	quit()
