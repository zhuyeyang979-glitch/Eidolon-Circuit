extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _puppet_bp(source_index: int) -> Dictionary:
	return {
		"name": "Thermal Pit Crew Probe",
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
	var source_index := main._component_index_by_name("puppet", "special", "CODE: THERMAL PIT CREW", -1)
	if source_index < 0:
		_fail("CODE: THERMAL PIT CREW should exist in puppet special catalog.")
		quit(1)
		return
	var part: Dictionary = main._selected_component("puppet", "special", source_index)
	var stats: Dictionary = main._compute_unit_stats(1, "puppet", 0, _puppet_bp(source_index))
	if String(part.get("kind", "")) != "code" or String(part.get("maker", "")) != "SYNTAX ELEVEN":
		_fail("Thermal pit crew should be a SYNTAX ELEVEN puppet code.")
	if int(stats.get("group_count", 0)) != 4 or String(stats.get("ai", "")) != "formation_xi":
		_fail("Thermal pit crew should spawn four formation_xi puppets.")
	if int(stats.get("module_sequence_limit", 0)) != 3 or int(stats.get("condition_slots", 0)) != 5:
		_fail("Thermal pit crew limits should be 3 modules and 5 source conditions.")
	if String(stats.get("source_target_policy", "")) != "heat_pressure_first":
		_fail("Thermal pit crew should use heat_pressure_first targeting.")
	if String(stats.get("source_attack_preference", "")) != "ranged_first" or String(stats.get("source_close_response", "")) != "screen":
		_fail("Thermal pit crew should screen while preferring ranged pressure.")
	if absf(float(stats.get("source_heat_focus_ratio", 0.0)) - 0.68) > 0.001:
		_fail("Thermal pit crew heat focus ratio should survive stats merge.")
	var rules: Dictionary = stats.get("source_rules", {})
	for condition in MainScene.SOURCE_CONDITION_ORDER:
		if not rules.has(condition):
			_fail("Thermal pit crew missing source rule: %s" % condition)
	if String(Dictionary(rules.get("enemy_shooting", {})).get("move", "")) != "screen":
		_fail("Thermal pit crew should screen into enemy shooting.")
	if String(Dictionary(rules.get("enemy_far", {})).get("move", "")) != "keep_range":
		_fail("Thermal pit crew should keep range against far targets.")
	if failed:
		quit(1)
		return
	print("THERMAL_PIT_CREW_SOURCE_CODE_PROBE ok index=%d" % source_index)
	quit()
