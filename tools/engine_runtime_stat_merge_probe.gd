extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _part(main, name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", "engine", name)
	if index < 0:
		_fail("Missing engine: %s" % name)
		return {}
	return main._selected_component("hero", "engine", index)


func _base_stats() -> Dictionary:
	return {
		"role": "hero",
		"mass": 80.0,
		"radius": 0.24,
		"speed": 1.0,
		"acceleration": 1.0,
		"normal_cooldown": 0.34,
		"active_cooldown": 0.74,
		"armor_cooldown": 0.5,
		"turn_acceleration": 4.2,
		"cornering": 1.0,
		"power_load": 80.0,
		"attitude_control": 0.85,
		"melee_stability_core": 0.85,
		"engine_power": 0.0,
		"engine_motion_scale": 1.0,
		"engine_weapon_tags": [],
		"engine_team_roles": [],
		"engine_heat_profiles": [],
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var ranged := _base_stats()
	main._merge_engine_stats(ranged, _part(main, "LONGSIGHT FIRE CONTROL CORE"))
	main._apply_engine_power_budget(ranged, "hero", true)
	if float(ranged.get("engine_recoil_stability", 1.0)) < 1.1:
		_fail("Ranged engine should merge fire-control stability.")
	if not Array(ranged.get("engine_weapon_tags", [])).has("sniper"):
		_fail("Ranged engine should merge weapon tags.")
	var booster := _base_stats()
	main._merge_engine_stats(booster, _part(main, "REDLINE BOOSTER REACTOR"))
	main._apply_engine_power_budget(booster, "hero", true)
	if float(booster.get("engine_boost_control", 1.0)) <= float(ranged.get("engine_boost_control", 1.0)):
		_fail("Booster engine should merge stronger boost control.")
	var siege := _base_stats()
	main._merge_engine_stats(siege, _part(main, "SIEGE GRID REACTOR"))
	main._apply_engine_power_budget(siege, "hero", true)
	if float(siege.get("support_power_capacity", 0.0)) <= float(ranged.get("support_power_capacity", 0.0)):
		_fail("Siege engine should create a stronger support power capacity.")
	if failed:
		quit(1)
		return
	print("ENGINE_RUNTIME_STAT_MERGE_PROBE ok ranged=%.2f booster=%.2f support=%.1f" % [float(ranged.get("engine_recoil_stability", 0.0)), float(booster.get("engine_boost_control", 0.0)), float(siege.get("support_power_capacity", 0.0))])
	quit()
