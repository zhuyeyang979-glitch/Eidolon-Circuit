extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _family_parts(main, family: String) -> Array:
	var result: Array = []
	var catalog: Array = main._catalog_for("hero", "engine")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "engine", i)
		if String(part.get("engine_family", "")).to_lower() == family:
			result.append(part)
	return result


func _max_value(parts: Array, field: String, fallback: float = 0.0) -> float:
	var value := -INF
	for raw in parts:
		var part: Dictionary = raw
		value = maxf(value, float(part.get(field, fallback)))
	return value


func _min_value(parts: Array, field: String, fallback: float = 0.0) -> float:
	var value := INF
	for raw in parts:
		var part: Dictionary = raw
		value = minf(value, float(part.get(field, fallback)))
	return value


func _avg_value(parts: Array, field: String, fallback: float = 0.0) -> float:
	if parts.is_empty():
		return fallback
	var sum := 0.0
	for raw in parts:
		var part: Dictionary = raw
		sum += float(part.get(field, fallback))
	return sum / float(parts.size())


func _rank(main, part: Dictionary) -> int:
	return int(main._payload_slot_volume_rank("engine", part, {"kind": "engine"}, "engine"))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var balanced := _family_parts(main, "balanced")
	var melee := _family_parts(main, "melee_drive")
	var ranged := _family_parts(main, "ranged_control")
	var booster := _family_parts(main, "booster_core")
	var swarm := _family_parts(main, "swarm_lite")
	var siege := _family_parts(main, "siege_reactor")
	for pair in [["balanced", balanced], ["melee_drive", melee], ["ranged_control", ranged], ["booster_core", booster], ["swarm_lite", swarm], ["siege_reactor", siege]]:
		if Array(pair[1]).is_empty():
			_fail("Family has no engines: %s" % String(pair[0]))
	if not failed:
		if _max_value(melee, "engine_command_drive", 1.0) <= _max_value(balanced, "engine_command_drive", 1.0):
			_fail("melee_drive should have stronger command drive than balanced")
		if _avg_value(ranged, "engine_heat_coeff", 0.0) >= _avg_value(melee, "engine_heat_coeff", 0.0):
			_fail("ranged_control should run cooler on average than melee_drive")
		if _max_value(ranged, "recoil_stability", 1.0) < 1.05:
			_fail("ranged_control should expose old recoil/fire-control stability")
		if _max_value(ranged, "engine_recoil_stability", 1.0) < 1.12:
			_fail("ranged_control should expose engine_recoil_stability")
		if _max_value(booster, "speed_mult", 1.0) <= _max_value(balanced, "speed_mult", 1.0):
			_fail("booster_core should provide stronger movement support than balanced")
		if _max_value(booster, "engine_boost_control", 1.0) <= _max_value(balanced, "engine_boost_control", 1.0):
			_fail("booster_core should provide stronger engine boost control than balanced")
		if _max_value(melee, "engine_command_drive", 1.0) <= _max_value(balanced, "engine_command_drive", 1.0):
			_fail("melee_drive should improve command drive over balanced")
		if _max_value(siege, "engine_supply_load", 1.0) <= _max_value(balanced, "engine_supply_load", 1.0):
			_fail("siege_reactor should expose heavier support load capacity")
		if _max_value(siege, "engine_momentum_output", 0.0) < _max_value(balanced, "engine_momentum_output", 0.0) * 1.75:
			_fail("siege_reactor should clearly exceed balanced peak momentum output")
		for raw in swarm:
			var part: Dictionary = raw
			if _rank(main, part) > 2:
				_fail("swarm_lite must stay XS/S, got rank %d on %s" % [_rank(main, part), String(part.get("name", ""))])
			if float(part.get("cost", 9999.0)) > 80.0:
				_fail("swarm_lite must stay cheap, got cost %.0f on %s" % [float(part.get("cost", 0.0)), String(part.get("name", ""))])
		for raw in siege:
			var part: Dictionary = raw
			if _rank(main, part) < 4:
				_fail("siege_reactor must be L/XL, got rank %d on %s" % [_rank(main, part), String(part.get("name", ""))])
	var stats := {
		"role": "hero",
		"mass": 72.0,
		"speed": 1.0,
		"acceleration": 1.0,
		"normal_cooldown": 0.34,
		"attack_cooldown": 0.5,
		"turn_speed": 1.0,
		"engine_momentum_output": 0.0,
		"engine_momentum_required": 80.0,
	}
	for raw in melee:
		main._merge_engine_stats(stats, raw)
	main._apply_engine_momentum_budget(stats, "hero", true)
	if float(stats.get("engine_command_drive", 1.0)) <= 1.0:
		_fail("melee engines should raise weighted engine_command_drive")
	if failed:
		quit(1)
		return
	print("ENGINE_PHILOSOPHY_PROBE ok command=%.2f ranged_heat_coeff=%.3f booster_speed=%.2f" % [_max_value(melee, "engine_command_drive", 1.0), _avg_value(ranged, "engine_heat_coeff", 0.0), _max_value(booster, "speed_mult", 1.0)])
	quit()
