extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _metric(main, slot_key: String, part: Dictionary) -> float:
	match slot_key:
		"engine":
			return main._engine_momentum_output_for_part(part)
		"booster":
			return main._thruster_drive_allocation_max_for_part(part) + main._thruster_boost_brake_allocation_max_for_part(part)
		"cooling":
			return main._cooling_rate_for_part(part) + main._cooling_heat_capacity_for_part(part) * 0.18
		"limb_muscle":
			return main._limb_momentum_max_for_part(part, slot_key) + main._part_stiffness(part, slot_key) * 0.08
		"muscle":
			if main._terminal_weapon_kind_for_part(part, "muscle") == "ranged":
				return main._projectile_momentum_for_event(part.duplicate(true)) * maxf(0.2, main._gun_projectile_damage_mult_max_for_data(part))
			if main._component_is_torso(part):
				return maxf(1.0, float(part.get("hp", 0.0)) + float(part.get("joint_ports", 0)) * 18.0)
			return main._part_stiffness(part, slot_key) * maxf(0.2, main._part_damage_coeff(part, slot_key))
	return maxf(1.0, float(part.get("cost", 0.0)))


func _median(values: Array) -> float:
	values.sort()
	return float(values[values.size() / 2])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var ratios_by_group := {}
	var checked := 0
	for slot_key in ["engine", "booster", "cooling", "limb_muscle", "muscle"]:
		for i in range(main._catalog_for("hero", slot_key).size()):
			var part: Dictionary = main._selected_component("hero", slot_key, i)
			if main._part_is_catalog_frozen(slot_key, part):
				continue
			var spec: Dictionary = main._part_gradient_spec(slot_key, part)
			var group_key := "%s|%s" % [slot_key, String(spec.get("role", spec.get("family", "")))]
			if not ratios_by_group.has(group_key):
				ratios_by_group[group_key] = []
			var cost := maxf(1.0, float(part.get("cost", 0.0)))
			var mass := maxf(0.2, float(part.get("mass", 0.0)))
			var value := _metric(main, slot_key, part)
			if value <= 0.0 or is_nan(value) or is_inf(value):
				_fail("%s/%s has invalid gradient metric %.3f" % [slot_key, String(part.get("name", "?")), value])
				continue
			ratios_by_group[group_key].append(value / sqrt(cost * mass))
			checked += 1
	for group_key in ratios_by_group.keys():
		var ratios: Array = ratios_by_group[group_key]
		if ratios.size() < 3:
			continue
		var median := maxf(0.001, _median(ratios.duplicate()))
		for ratio in ratios:
			var normalized := float(ratio) / median
			if normalized > 120.0 or normalized < 0.008:
				_fail("%s has extreme value/cost/mass outlier ratio %.3f vs median %.3f" % [String(group_key), float(ratio), median])
	if checked <= 0:
		_fail("No live parts checked.")
	if failed:
		quit(1)
		return
	print("PART_GRADIENT_OUTLIER_PROBE ok checked=%d groups=%d" % [checked, ratios_by_group.size()])
	quit()
