extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _special_index(role_key: String, item_name: String) -> int:
	var catalog: Array = MainScene.SPECIAL_CATALOG[role_key]
	for i in range(catalog.size()):
		if String(Dictionary(catalog[i]).get("name", "")) == item_name:
			return i
	return -1


func _part_index(slot_key: String, item_name: String) -> int:
	var catalog: Array = MainScene.COMMON_CATALOG[slot_key]
	for i in range(catalog.size()):
		if String(Dictionary(catalog[i]).get("name", "")) == item_name:
			return i
	return -1


func _barrier_bp(special_index: int, extra_ethers: Array = []) -> Dictionary:
	var wall_muscle := _part_index("muscle", "MAZE HARDLIGHT CAGE WALL PANEL")
	var elbow_joint := _part_index("joint", "TIMBER 90 MAZE ELBOW JOINT")
	if wall_muscle < 0 or elbow_joint < 0:
		_fail("Missing maze wall component for plain ether probe.")
	return {
		"name": "Plain Ether Probe",
		"archetype": "custom",
		"special": special_index,
		"joint": elbow_joint,
		"limb_muscle": 0,
		"muscle": wall_muscle,
		"booster": 0,
		"engine": 0,
		"cooling": 5,
		"module": 10,
		"ether_group": extra_ethers,
		"barrier_tiles": [
			{"index": 0, "muscle": wall_muscle},
			{"index": 9, "joint": elbow_joint},
		],
	}


func _spawn_heat_probe(main, cooling: float):
	var stats: Dictionary = main._compute_unit_stats(1, "hero", 0).duplicate(true)
	stats["name"] = "Heat Economy Probe"
	stats["role"] = "hero"
	stats["health"] = 100
	stats["mass"] = 80.0
	stats["cooling"] = cooling
	stats["heat_capacity"] = 100.0
	stats["engine_motion_scale"] = 1.0
	stats["load_overload_ratio"] = 1.0
	var unit = main._create_unit(1, "hero", stats, "HEAT PROBE", 1.0, 0.0)
	main._assign_unit_role(unit, "hero")
	return unit


func _heat_group(module_name: String) -> Dictionary:
	return {
		"name": "HEAT TEST LIMB",
		"module_name": module_name,
		"motion": "rod",
		"damage_type": "blunt",
		"damage_mult": 1.0,
		"joint_power": 4.0,
		"joint_mass": 10.0,
		"muscle_mass": 20.0,
		"terminal_weapon_mass": 18.0,
		"terminal_weapon": true,
		"range_mult": 1.0,
	}


func _heat_event(main, unit, group: Dictionary) -> Dictionary:
	var state_key := "normal"
	return {
		"state": state_key,
		"projectile": false,
		"damage": 12,
		"group_name": String(group.get("name", "")),
		"collision_group": group.duplicate(true),
		"weapon_damage_coeff": main._weapon_damage_coefficient(12.0, group, state_key),
		"joint_actuation_speed": main._group_joint_actuation_speed(unit.stats, group, state_key),
		"limb_end_mass": main._group_limb_end_mass(group, unit.stats),
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var origin: Dictionary = MainScene.SPECIAL_CATALOG["barrier"][0]
	if String(origin.get("name", "")) != "ETHER: ORIGIN PIN":
		_fail("First ether should be ETHER: ORIGIN PIN.")
	if String(origin.get("barrier_logic", "")) != "structure_only" or bool(origin.get("is_gravity_field", false)):
		_fail("Origin Pin should be a plain structure-only ether.")
	for forbidden in ["aura_heat", "ally_cooling", "slow_power", "active_damage", "gravity_force"]:
		if origin.has(forbidden):
			_fail("Origin Pin should not carry field effect: %s" % forbidden)

	var expected := {
		"ETHER FRAME SEED": {"cap": 1, "bind": 4.0, "cost": 26},
		"ETHER FRAME ROOM": {"cap": 2, "bind": 8.0, "cost": 58},
		"ETHER FRAME WARD": {"cap": 3, "bind": 12.0, "cost": 96},
		"ETHER FRAME DISTRICT": {"cap": 4, "bind": 16.0, "cost": 148},
		"ETHER FRAME CONSTELLATION": {"cap": 6, "bind": 22.0, "cost": 230},
	}
	for name in expected.keys():
		var idx := _special_index("barrier", name)
		if idx < 0:
			_fail("Missing plain ether: %s" % name)
		var part: Dictionary = MainScene.SPECIAL_CATALOG["barrier"][idx]
		var rule: Dictionary = expected[name]
		if String(part.get("barrier_logic", "")) != "structure_only":
			_fail("%s should use structure_only logic." % name)
		if bool(part.get("is_gravity_field", false)) or String(part.get("barrier_damage_type", "")) != "":
			_fail("%s should not carry a combat field effect." % name)
		main.blueprints[1]["barrier"] = [_barrier_bp(idx)]
		var stats: Dictionary = main._compute_unit_stats(1, "barrier", 0)
		print("PLAIN_ETHER %s cap=%d bind=%.1f cost=%d logic=%s" % [
			name,
			int(stats.get("ether_group_capacity", 0)),
			float(stats.get("ether_bind_radius_m", 0.0)),
			int(part.get("cost", 0)),
			String(stats.get("barrier_logic", "")),
		])
		if int(stats.get("ether_group_capacity", 0)) != int(rule["cap"]):
			_fail("%s capacity mismatch." % name)
		if absf(float(stats.get("ether_bind_radius_m", 0.0)) - float(rule["bind"])) > 0.01:
			_fail("%s bind radius mismatch." % name)
		if int(part.get("cost", 0)) != int(rule["cost"]):
			_fail("%s cost mismatch." % name)

	var constellation := _special_index("barrier", "ETHER FRAME CONSTELLATION")
	var district := _special_index("barrier", "ETHER FRAME DISTRICT")
	var ward := _special_index("barrier", "ETHER FRAME WARD")
	main.blueprints[1]["barrier"] = [_barrier_bp(constellation, [district, ward])]
	var group_stats: Dictionary = main._compute_unit_stats(1, "barrier", 0)
	if int(group_stats.get("ether_count", 0)) != 3 or int(group_stats.get("ether_group_capacity", 0)) != 3:
		_fail("Plain ether group should allow constellation + district + ward as exactly three linked ethers.")

	main._clear_all_units()
	var unit = _spawn_heat_probe(main, 45.0)
	var group_a := _heat_group("HEAT MODULE A")
	var first_event := _heat_event(main, unit, group_a)
	main._apply_melee_module_heat(unit, first_event, group_a, 0)
	var first_heat := float(unit.heat)
	var second_event := _heat_event(main, unit, group_a)
	main._apply_melee_module_heat(unit, second_event, group_a, 0)
	var second_delta := float(unit.heat) - first_heat
	var group_b := _heat_group("HEAT MODULE B")
	var before_combo := float(unit.heat)
	var combo_event := _heat_event(main, unit, group_b)
	main._apply_melee_module_heat(unit, combo_event, group_b, 1)
	var combo_delta := float(unit.heat) - before_combo
	print("HEAT_ECON first=%.3f second_delta=%.3f combo_delta=%.3f raw=%.3f offset=%.3f repeat_stack=%d repeat_mult=%.2f" % [
		first_heat,
		second_delta,
		combo_delta,
		float(second_event.get("module_heat_raw", 0.0)),
		float(second_event.get("module_heat_cooling_offset", 0.0)),
		int(second_event.get("module_heat_repeat_stack", 0)),
		float(second_event.get("module_heat_repeat_mult", 0.0)),
	])
	if int(second_event.get("module_heat_repeat_stack", 0)) != 1:
		_fail("Second same-module use should have one repeat stack.")
	if first_heat < -0.001 or second_delta < -0.001 or combo_delta < -0.001:
		_fail("Heat economy deltas should never be negative.")
	if combo_delta > second_delta + 0.05:
		_fail("Switching to another module should not be hotter than repeating the same module.")
	quit()
