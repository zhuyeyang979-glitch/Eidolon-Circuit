extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _puppet_bp(source_index: int) -> Dictionary:
	return {
		"name": "Triage Lattice Probe",
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
	var source_index := main._component_index_by_name("puppet", "special", "CODE: TRIAGE LATTICE", -1)
	if source_index < 0:
		_fail("CODE: TRIAGE LATTICE should exist in puppet special catalog.")
		quit(1)
		return
	var part: Dictionary = main._selected_component("puppet", "special", source_index)
	var stats: Dictionary = main._compute_unit_stats(1, "puppet", 0, _puppet_bp(source_index))
	if String(part.get("kind", "")) != "code" or String(part.get("maker", "")) != "HELIX CIVIC":
		_fail("Triage lattice should be a HELIX CIVIC puppet code.")
	if int(stats.get("group_count", 0)) != 4 or String(stats.get("ai", "")) != "vanguard_cover":
		_fail("Triage lattice should spawn four vanguard_cover puppets.")
	if int(stats.get("module_sequence_limit", 0)) != 3 or int(stats.get("condition_slots", 0)) != 5:
		_fail("Triage lattice limits should be 3 modules and 5 source conditions.")
	if String(stats.get("source_target_policy", "")) != "protect_puppet_group":
		_fail("Triage lattice should protect allied puppet groups.")
	if String(stats.get("source_attack_preference", "")) != "intercept_first":
		_fail("Triage lattice should prefer intercept-first attacks.")
	var rules: Dictionary = stats.get("source_rules", {})
	if String(Dictionary(rules.get("enemy_close", {})).get("move", "")) != "cover_retreat":
		_fail("Triage lattice should cover-retreat from close threats.")
	if String(Dictionary(rules.get("enemy_shooting", {})).get("move", "")) != "intercept":
		_fail("Triage lattice should intercept enemy shooting.")
	if String(Dictionary(rules.get("default", {})).get("move", "")) != "cover_group":
		_fail("Triage lattice should default to cover_group.")

	var triage = main._create_unit(1, "puppet", stats, "TRIAGE", 4.0, 0.0)
	var own_hero_stats: Dictionary = main._compute_unit_stats(1, "hero", 0)
	var own_hero = main._create_unit(1, "hero", own_hero_stats, "OWN HERO", 3.2, 0.0)
	var damaged_stats := stats.duplicate(true)
	damaged_stats["health"] = 100
	var damaged_ally = main._create_unit(1, "puppet", damaged_stats, "DAMAGED ALLY", 4.42, 0.0)
	damaged_ally.max_health = 100
	damaged_ally.health = 20
	var far_hero_stats: Dictionary = main._compute_unit_stats(2, "hero", 0)
	var far_hero = main._create_unit(2, "hero", far_hero_stats, "FAR HERO", 7.2, 0.0)
	var threat_stats := stats.duplicate(true)
	var close_threat = main._create_unit(2, "puppet", threat_stats, "CLOSE THREAT", 4.54, 0.0)
	close_threat.set_meta("projectile_signal", 0.5)
	main.active_units[1]["hero"] = own_hero
	main.active_units[1]["puppet"] = [triage, damaged_ally]
	main.active_units[2]["hero"] = far_hero
	main.active_units[2]["puppet"] = [close_threat]
	var target = main._source_target_for_puppet(triage, 1)
	if target != close_threat:
		_fail("Triage lattice should prioritize the threat pressing the damaged allied puppet group.")
	if failed:
		quit(1)
		return
	print("TRIAGE_LATTICE_SOURCE_CODE_PROBE ok index=%d" % source_index)
	quit()
