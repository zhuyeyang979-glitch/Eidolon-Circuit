extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _barrier_bp() -> Dictionary:
	return {
		"name": "Origin Pin Probe",
		"archetype": "custom",
		"special": 0,
		"joint": 30,
		"limb_muscle": 0,
		"muscle": 14,
		"booster": 0,
		"engine": 0,
		"cooling": 5,
		"module": 10,
		"barrier_tiles": [
			{"index": 0, "joint": 30},
			{"index": 1, "joint": 31},
		],
	}


func _init() -> void:
	var first: Dictionary = MainScene.SPECIAL_CATALOG["barrier"][0]
	if String(first.get("name", "")) != "ETHER: ORIGIN PIN":
		_fail("Barrier special index 0 should be ETHER: ORIGIN PIN.")
	if String(first.get("kind", "")) != "ether" or String(first.get("maker", "")) != "NULL SOFTWARE":
		_fail("Origin Pin should be a NULL SOFTWARE ether.")
	if int(first.get("cost", 0)) != 18 or int(first.get("power", 0)) != 4 or int(first.get("energy", 0)) != 2:
		_fail("Origin Pin economy values changed unexpectedly.")
	if int(first.get("fixed", 0)) != 2 or int(first.get("material_slots", 0)) != 6:
		_fail("Origin Pin should teach a tiny six-material disconnected barrier.")
	if absf(float(first.get("space_size", 0.0)) - 0.42) > 0.001:
		_fail("Origin Pin space size should be 0.42.")
	if absf(float(first.get("ether_bind_radius_m", 0.0)) - 3.2) > 0.001:
		_fail("Origin Pin bind radius should be 3.2m.")
	if int(first.get("ether_link_capacity", -1)) != 0 or String(first.get("ether_group_kind", "")) != "origin_pin":
		_fail("Origin Pin should be a single origin_pin ether with no link capacity.")
	if String(first.get("barrier_logic", "")) != "structure_only" or not bool(first.get("barrier_disconnected", false)):
		_fail("Origin Pin should be structure_only and disconnected.")
	for forbidden in ["aura_heat", "ally_cooling", "slow_power", "active_damage", "gravity_force", "projectile", "attack_groups", "action_groups"]:
		if first.has(forbidden):
			_fail("Origin Pin must not expose combat or legacy field: %s" % forbidden)
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var stats: Dictionary = main._compute_unit_stats(1, "barrier", 0, _barrier_bp())
	if int(stats.get("ether_count", 0)) != 1:
		_fail("Origin Pin should merge as exactly one ether.")
	if int(stats.get("material_slots", 0)) != 6 or int(stats.get("ether_group_capacity", 0)) != 1:
		_fail("Origin Pin merged material slots or group capacity mismatch.")
	if String(stats.get("barrier_logic", "")) != "structure_only":
		_fail("Origin Pin runtime barrier logic should stay structure_only.")
	if float(stats.get("aura_range", -1.0)) != 0.0 or not Array(stats.get("ether_effects", [])).is_empty():
		_fail("Origin Pin should not create aura or utility effects.")
	print("FIRST_ETHER_ORIGIN_PIN_PROBE ok")
	quit()
