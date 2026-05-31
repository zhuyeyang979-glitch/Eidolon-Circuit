extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _muscle_index(item_name: String) -> int:
	var catalog: Array = MainScene.COMMON_CATALOG["muscle"]
	for i in range(catalog.size()):
		if String(Dictionary(catalog[i]).get("name", "")) == item_name:
			return i
	return -1


func _base_barrier_bp(tile_names: Array) -> Dictionary:
	var tiles: Array = []
	var index := 0
	for item_name in tile_names:
		var muscle_index := _muscle_index(String(item_name))
		if muscle_index < 0:
			_fail("Missing maze barrier panel: %s" % String(item_name))
		var part: Dictionary = MainScene.COMMON_CATALOG["muscle"][muscle_index]
		if not bool(part.get("barrier_panel", false)) or not bool(part.get("barrier_tile_component", false)):
			_fail("%s is not registered as a barrier panel tile." % String(item_name))
		tiles.append({"index": index, "muscle": muscle_index})
		index += 3
	return {
		"name": "Maze Panel Probe",
		"archetype": "custom",
		"special": 0,
		"joint": 30,
		"limb_muscle": 0,
		"muscle": _muscle_index("MAZE HARDLIGHT CAGE WALL PANEL"),
		"booster": 0,
		"engine": 0,
		"cooling": 5,
		"module": 10,
		"barrier_tiles": tiles,
	}


func _catalog_part(main, item_name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", "muscle", item_name)
	if index < 0:
		_fail("Missing barrier catalog part: %s" % item_name)
		return {}
	return main._selected_component("hero", "muscle", index)


func _assert_live_panel(main, item_name: String) -> void:
	var part := _catalog_part(main, item_name)
	if part.is_empty():
		return
	if main._part_is_catalog_frozen("muscle", part):
		_fail("%s should be live." % item_name)
	if not bool(part.get("barrier_panel", false)) or not bool(part.get("barrier_tile_component", false)):
		_fail("%s should retain barrier panel runtime flags." % item_name)


func _assert_frozen_panel(main, item_name: String) -> void:
	var part := _catalog_part(main, item_name)
	if part.is_empty():
		return
	if not main._part_is_catalog_frozen("muscle", part):
		_fail("%s should stay frozen." % item_name)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for item_name in [
		"VAULT DIVIDEND BULKHEAD",
		"CRUSTA PRESSURE GATE PANEL",
		"LONGSIGHT ONE-WAY SNIPER SCREEN",
		"COINRUN JACKPOT BLOCK",
		"MAZE RIGHT GRAVITY FLOOR PANEL",
		"MAZE REPAIR DOCK FLOOR PANEL",
		"MAZE SPEED RAIL STRIP PANEL",
		"MAZE BULLET RICOCHET WALL PANEL",
		"MAZE ENTRY BREACH CHARGE PANEL",
		"MAZE HARDLIGHT CAGE WALL PANEL",
	]:
		_assert_live_panel(main, String(item_name))
	_assert_frozen_panel(main, "REDLINE SHELL CRATER PANEL")
	var panel_names := [
		"MAZE RIGHT GRAVITY FLOOR PANEL",
		"MAZE COOLANT FLOOR PANEL",
		"MAZE HEAT PRESSURE FLOOR PANEL",
		"MAZE REPULSOR FLOOR PANEL",
		"MAZE HACKING MIST PANEL",
		"MAZE SIGNAL JAMMER WALL PANEL",
		"MAZE ACID RAIN TRIGGER PANEL",
		"MAZE BULLET RICOCHET WALL PANEL",
		"MAZE AMMO KIOSK FLOOR PANEL",
		"MAZE REPAIR DOCK FLOOR PANEL",
		"MAZE SPEED RAIL STRIP PANEL",
		"MAZE COIN MINT BLOCK PANEL",
		"MAZE ONE-WAY FIRING SCREEN PANEL",
		"MAZE ENTRY BREACH CHARGE PANEL",
		"MAZE HARDLIGHT CAGE WALL PANEL",
	]
	main.blueprints[1]["barrier"] = [_base_barrier_bp(panel_names)]
	var stats: Dictionary = main._compute_unit_stats(1, "barrier", 0)
	print("MAZE_PANEL_FLAGS gravity=%s coolant=%s heat=%s repulse=%s hack=%s jam=%s trap=%s reflect=%s support=%s repair=%s speed=%s coin=%s shield=%s breach=%d cage=%s tiles=%d" % [
		str(bool(stats.get("is_gravity_field", false))),
		str(bool(stats.get("is_coolant_field", false))),
		str(bool(stats.get("is_heat_field", false))),
		str(bool(stats.get("is_repulsion_field", false))),
		str(bool(stats.get("is_hack_field", false))),
		str(bool(stats.get("is_signal_jammer", false))),
		str(bool(stats.get("is_trap_field", false))),
		str(bool(stats.get("reflect_projectiles", false))),
		str(bool(stats.get("is_support_node", false))),
		str(bool(stats.get("is_repair_station", false))),
		str(bool(stats.get("is_speed_lane", false))),
		str(bool(stats.get("is_coin_generator", false))),
		str(bool(stats.get("is_one_way_shield", false))),
		int(stats.get("entry_breach_damage", 0)),
		str(bool(stats.get("is_cage_wall", false))),
		Array(stats.get("barrier_map_tiles", [])).size(),
	])
	for required_flag in ["is_gravity_field", "is_coolant_field", "is_heat_field", "is_repulsion_field", "is_hack_field", "is_signal_jammer", "is_trap_field", "reflect_projectiles", "is_support_node", "is_repair_station", "is_speed_lane", "is_coin_generator", "is_one_way_shield", "is_cage_wall"]:
		if not bool(stats.get(required_flag, false)):
			_fail("Barrier tile stats did not merge %s." % required_flag)
	if int(stats.get("entry_breach_damage", 0)) <= 0:
		_fail("Entry breach panel did not merge into barrier stats.")
	var gravity_effects: Array = Array(stats.get("ether_effects", []))
	if gravity_effects.is_empty():
		_fail("Gravity floor panel did not create a tile gravity effect.")
	var reflect_types: Array = Array(stats.get("reflect_types", []))
	if not reflect_types.has("bullet"):
		_fail("Bullet reflector panel did not merge reflect_types.")
	var seen_tags := {}
	for raw_tile in Array(stats.get("barrier_map_tiles", [])):
		if not (raw_tile is Dictionary):
			continue
		for raw_tag in Array(Dictionary(raw_tile).get("effect_tags", [])):
			seen_tags[String(raw_tag)] = true
	for tag in ["gravity", "coolant", "heat", "repulsion", "hack", "jammer", "trap", "reflector", "support", "speed_lane", "coin", "one_way_shield", "entry_breach", "cage"]:
		if not bool(seen_tags.get(tag, false)):
			_fail("Runtime barrier tile missing effect tag: %s" % tag)
	print("MAZE_PANEL_TAGS %s" % [",".join(seen_tags.keys())])
	quit()
