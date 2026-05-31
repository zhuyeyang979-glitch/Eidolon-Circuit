extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _median_mass(rank: int) -> float:
	return float(MainScene.ECONOMY_MEDIAN_MASS_BY_RANK.get(clampi(rank, 1, 5), 48.0))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var seen_ranks := {}
	var seen_families := {}
	var target_ranks := {}
	var required_fields := [
		"thruster_family",
		"drive_demand",
		"momentum_min",
		"momentum_max",
		"move_efficiency",
		"boost_efficiency",
		"turn_efficiency",
		"movement_profile",
		"boost_angle_degrees",
		"boost_cooldown",
		"boost_heat",
		"thruster_duration",
		"boost_momentum",
		"boost_duration",
		"thruster_idle_heat_coeff",
		"mass",
		"cost",
		"slot_volume_tier",
		"flame_color",
		"summary",
	]
	var legacy_fields := ["boost_power", "normal_thrust", "boost_cone", "booster_size", "boost_style", "boost_flame", "boost_sustain"]
	var catalog: Array = main._catalog_for("hero", "booster")
	for i in range(catalog.size()):
		var part: Dictionary = main._thruster_with_drive_defaults(main._selected_component("hero", "booster", i))
		var name := String(part.get("name", "booster-%d" % i))
		for field in required_fields:
			if not part.has(field):
				_fail("%s missing required thruster field %s" % [name, field])
		for field in legacy_fields:
			if part.has(field):
				_fail("%s still has legacy thruster field %s" % [name, field])
		var rank := int(main._payload_slot_volume_rank("booster", part, {"kind": "booster"}, "booster"))
		if rank < 1 or rank > 5:
			_fail("%s has invalid slot rank %d" % [name, rank])
		seen_ranks[rank] = true
		seen_families[String(part.get("thruster_family", "")).to_lower()] = true
		var drive_min := main._thruster_drive_allocation_min_for_part(part)
		var drive_max := main._thruster_drive_allocation_max_for_part(part)
		var boost_min := main._thruster_boost_brake_allocation_min_for_part(part)
		var boost_max := main._thruster_boost_brake_allocation_max_for_part(part)
		if drive_min <= 0.0:
			_fail("%s must expose positive drive allocation min" % name)
		if drive_max + 0.01 < drive_min * MainScene.THRUSTER_ALLOCATION_MAX_MULT:
			_fail("%s drive allocation max should be 3x min" % name)
		if boost_min > 0.0 and boost_max + 0.01 < boost_min * MainScene.THRUSTER_ALLOCATION_MAX_MULT:
			_fail("%s boost/brake allocation max should be 3x min" % name)
		if main._booster_normal_momentum_for_part(part) <= 0.0:
			_fail("%s must expose positive movement momentum" % name)
		if float(part.get("thruster_duration", 0.0)) <= 0.0 or float(part.get("boost_duration", 0.0)) <= 0.0:
			_fail("%s must expose positive durations" % name)
		var median := _median_mass(rank)
		if main._booster_normal_momentum_for_part(part) + 0.01 >= median * 2.0 and main._thruster_boost_total_momentum_for_part(part) + 0.01 >= median * 4.0:
			target_ranks[rank] = true
		var gradient: Dictionary = main._part_gradient_spec("booster", part)
		if String(gradient.get("rank_label", "")) == "" or Array(gradient.get("tradeoff_tags", [])).is_empty():
			_fail("%s must expose gradient rank and tradeoff tags." % name)
	for rank in range(1, 6):
		if not seen_ranks.has(rank):
			_fail("No thruster exists for slot rank %d" % rank)
		if not target_ranks.has(rank):
			_fail("No thruster reaches same-size median movement target for rank %d" % rank)
	for family in ["cruise_blue", "sustain_yellow", "overburn_red", "counter_brake", "swarm_micro", "titan_vector"]:
		if not seen_families.has(family):
			_fail("Missing thruster family %s" % family)
	if failed:
		quit(1)
		return
	print("THRUSTER_GRADIENT_CATALOG_PROBE ok boosters=%d families=%d ranks=%d" % [catalog.size(), seen_families.size(), seen_ranks.size()])
	quit()
