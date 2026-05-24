extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false
var booster_target_ranks := {}


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _approx(label: String, actual: float, expected: float, tolerance: float = 0.05) -> void:
	if absf(actual - expected) > tolerance:
		_fail("%s expected %.3f got %.3f" % [label, expected, actual])


func _median_mass(rank: int) -> float:
	return float(MainScene.ECONOMY_MEDIAN_MASS_BY_RANK.get(clampi(rank, 1, 5), 48.0))


func _check_slot(main, slot_key: String) -> void:
	var catalog: Array = main._catalog_for("hero", slot_key)
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", slot_key, i)
		var rank := int(main._payload_slot_volume_rank(slot_key, part, {"kind": slot_key}, slot_key))
		if rank < 1 or rank > 5:
			_fail("%s rank out of bounds for %s" % [slot_key, String(part.get("name", ""))])
			continue
		var median := _median_mass(rank)
		if slot_key == "engine":
			if float(part.get("engine_momentum_output", 0.0)) + 0.01 < main._economy_engine_momentum_target(rank):
				_fail("Engine momentum output below economy target: %s" % String(part.get("name", "")))
			if float(part.get("engine_heat_coeff", 0.0)) <= 0.0:
				_fail("Engine lacks explicit heat coefficient: %s" % String(part.get("name", "")))
		elif slot_key == "booster":
			var expected_move_momentum := median * 2.0
			var expected_boost_momentum := median * 4.0
			for field in ["thruster_family", "drive_demand", "momentum_min", "momentum_max", "move_efficiency", "boost_efficiency", "turn_efficiency", "movement_profile", "boost_angle_degrees", "boost_cooldown", "boost_heat", "thruster_duration", "boost_duration", "thruster_idle_heat_coeff", "brake_efficiency", "flame_color", "summary"]:
				if not part.has(field):
					_fail("Booster missing %s: %s" % [field, String(part.get("name", ""))])
			if absf(main._thruster_drive_demand_for_part(part) - float(part.get("momentum_min", 0.0))) > 0.001:
				_fail("Booster fixed demand should equal momentum_min: %s" % String(part.get("name", "")))
			if main._booster_normal_momentum_for_part(part) <= 0.0:
				_fail("Booster fixed demand does not produce normal movement momentum: %s" % String(part.get("name", "")))
			if main._thruster_boost_total_momentum_for_part(part) <= 0.0:
				_fail("Booster fixed demand does not produce boost total momentum: %s" % String(part.get("name", "")))
			if float(part.get("thruster_duration", 0.0)) <= 0.0 or float(part.get("boost_duration", 0.0)) <= 0.0:
				_fail("Booster lacks positive durations: %s" % String(part.get("name", "")))
			if main._booster_normal_momentum_for_part(part) + 0.01 >= expected_move_momentum and main._thruster_boost_total_momentum_for_part(part) + 0.01 >= expected_boost_momentum:
				booster_target_ranks[rank] = true
			var demand: float = main._thruster_drive_demand_for_part(part)
			var boost_extra: float = main._booster_boost_momentum_for_part(part)
			var stats := {"role": "hero", "mass": median, "thruster_drive_demand": demand, "thruster_allocated_momentum": 9999.0, "thruster_boost_extra_demand": boost_extra, "thruster_boost_peak_demand": demand + boost_extra, "engine_momentum_output": demand + boost_extra + 1.0, "boost_momentum": float(part.get("boost_momentum", 0.0)), "move_efficiency": float(part.get("move_efficiency", 1.0)), "boost_efficiency": float(part.get("boost_efficiency", MainScene.ECONOMY_BOOST_MOMENTUM_MULT)), "turn_efficiency": float(part.get("turn_efficiency", 1.0)), "boost_duration": float(part.get("boost_duration", 0.3)), "speed_mult": 1.0}
			main._apply_engine_momentum_budget(stats, "hero")
			main._apply_thruster_momentum_stats(stats, "hero")
			if float(stats.get("body_move_speed", 0.0)) <= 0.0 or float(stats.get("boost_speed", 0.0)) <= 0.0:
				_fail("Booster does not produce movement speeds: %s" % String(part.get("name", "")))
		elif slot_key == "cooling":
			if float(part.get("cooling", 0.0)) + 0.01 < main._economy_cooling_target(rank):
				_fail("Cooling below same-size target: %s" % String(part.get("name", "")))
			if float(part.get("heat_capacity", 0.0)) + 0.01 < main._economy_heat_capacity_target(rank):
				_fail("Cooling heat capacity below target: %s" % String(part.get("name", "")))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for slot_key in ["engine", "booster", "cooling"]:
		_check_slot(main, slot_key)
	for rank in range(1, 6):
		if not booster_target_ranks.has(rank):
			_fail("No booster reaches same-size median target for rank %d." % rank)
	for rank in range(1, 6):
		var engine := {"name": "E", "slot_volume_tier": main._volume_rank_label(float(rank)), "engine_momentum_output": 0, "mass": 1}
		var booster := {"name": "B", "slot_volume_tier": main._volume_rank_label(float(rank)), "mass": 1}
		var cooling := {"name": "C", "slot_volume_tier": main._volume_rank_label(float(rank)), "cooling": 0, "mass": 1}
		engine = main._economy_rebalanced_plugin_component(engine, "engine")
		booster = main._economy_rebalanced_plugin_component(booster, "booster")
		cooling = main._economy_rebalanced_plugin_component(cooling, "cooling")
		if float(engine.get("engine_momentum_output", 0.0)) < main._economy_engine_momentum_target(rank):
			_fail("Synthetic same-size engine target failed rank %d." % rank)
		if float(cooling.get("cooling", 0.0)) < main._engine_idle_heat_for_part(engine, float(engine.get("engine_momentum_output", 0.0))) + main._booster_idle_heat_for_part(booster):
			_fail("Synthetic same-size cooling does not cover idle heat rank %d." % rank)
	if failed:
		quit(1)
		return
	print("ENGINE_THRUSTER_COOLING_ECONOMY_PROBE ok")
	quit()
