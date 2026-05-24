extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var raw := {
		"name": "Probe Cooler",
		"slot_volume_tier": "M",
		"cooling": 500.0,
		"cooling_rate": 500.0,
		"heat_dissipation": 500.0,
		"heat_capacity": 999.0,
		"manual_cooling_bonus": 7.0,
	}
	var adjusted := main._cooling_with_v3_defaults(raw)
	if absf(float(adjusted.get("cooling", 0.0)) - 500.0) > 0.01:
		_fail("Cooling output pool alias should not double.")
	if absf(float(adjusted.get("cooling_rate", 0.0)) - 500.0) > 0.01:
		_fail("Cooling rate should not double.")
	if absf(float(adjusted.get("heat_dissipation", 0.0)) - 500.0) > 0.01:
		_fail("Heat dissipation should not double.")
	if absf(float(adjusted.get("heat_capacity", 0.0)) - 1998.0) > 0.01:
		_fail("Cooling pool / heat capacity should double.")
	if absf(float(adjusted.get("manual_cooling_bonus", 0.0)) - 7.0) > 0.01:
		_fail("Manual cooling should not double.")
	var second := main._cooling_with_v3_defaults(adjusted)
	if absf(float(second.get("heat_capacity", 0.0)) - 1998.0) > 0.01:
		_fail("Cooling pool scaling should be idempotent on normalized parts.")
	var public_marker_only := adjusted.duplicate(true)
	public_marker_only.erase("_cooling_pool_scaled")
	var third := main._cooling_with_v3_defaults(public_marker_only)
	if absf(float(third.get("heat_capacity", 0.0)) - 1998.0) > 0.01:
		_fail("Cooling pool scaling should be idempotent when only the public scale marker remains.")
	if absf(main._cooling_rate_for_part(raw) - 500.0) > 0.01:
		_fail("Cooling display helper should keep raw cooling rate.")
	if absf(main._cooling_dissipation_for_part(raw) - 500.0) > 0.01:
		_fail("Cooling dissipation helper should keep raw dissipation.")
	if absf(main._cooling_heat_capacity_for_part(raw) - 1998.0) > 0.01:
		_fail("Cooling pool helper should double heat capacity.")
	var payload_line := main._payload_detail_line("cooling", raw)
	if payload_line.find("1998") == -1:
		_fail("Cooling payload detail should display doubled pool, got: %s" % payload_line)
	var catalog_lines: Array = main._catalog_card_data_lines("cooling", raw)
	if catalog_lines.is_empty() or String(catalog_lines[0]).find("1998") == -1:
		_fail("Cooling catalog card should display doubled pool, got: %s" % str(catalog_lines))
	var stats := {"cooling": 0.0, "heat_dissipation": 0.0, "cooling_heat_capacity": 0.0, "heat_capacity": 0.0, "speed_mult": 1.0, "cost": 0, "mass": 0.0, "energy": 0.0, "power_load": 0.0}
	main._merge_internal_payload_stats(stats, raw, "cooling")
	if absf(float(stats.get("cooling", 0.0)) - 500.0) > 0.01:
		_fail("Internal cooling payload stats should keep raw cooling output.")
	if absf(float(stats.get("heat_dissipation", 0.0)) - 500.0) > 0.01:
		_fail("Internal cooling payload heat dissipation should keep raw output.")
	if absf(float(stats.get("cooling_heat_capacity", 0.0)) - 1998.0) > 0.01:
		_fail("Internal cooling payload stats should use doubled cooling pool.")
	stats["engine_idle_heat"] = 620.0
	stats["booster_idle_heat"] = 180.0
	stats["bound_limb_idle_heat"] = 90.0
	main._apply_thermal_budget(stats, "hero")
	if String(stats.get("thermal_note", "")).begins_with("INVALID"):
		_fail("Doubled cooling pool should carry high idle load even though cooling speed is unchanged.")
	if absf(float(stats.get("cooling", 0.0)) - 500.0) > 0.01:
		_fail("Thermal budget must not double cooling speed.")
	if absf(float(stats.get("heat_capacity", 0.0)) - 1998.0) > 0.01:
		_fail("Runtime heat pool should use doubled cooling capacity.")
	if absf(float(stats.get("thermal_margin", 0.0)) - (1998.0 - 890.0)) > 0.01:
		_fail("Thermal margin should be heat pool minus idle load, not cooling speed minus idle load.")
	for part_raw in main._catalog_for("hero", "cooling"):
		if not (part_raw is Dictionary):
			continue
		var part := Dictionary(part_raw)
		var catalog_capacity := float(part.get("heat_capacity", 0.0))
		if absf(main._cooling_heat_capacity_for_part(part) - catalog_capacity) > 0.01:
			_fail("%s catalog cooling pool should already be normalized and idempotent." % String(part.get("name", "?")))
	print("COOLER_POOL_DOUBLE_PROBE ok pool=%.1f rate=%.1f" % [float(adjusted.get("heat_capacity", 0.0)), float(adjusted.get("cooling_rate", 0.0))])
	quit()
