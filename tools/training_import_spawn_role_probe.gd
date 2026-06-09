extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _cleanup_main(main) -> void:
	if main == null:
		return
	if main.get_parent() != null:
		main.get_parent().remove_child(main)
	main.queue_free()


func _live_import_for_role(main, owner: int, role_key: String):
	var units: Dictionary = main.active_units.get(owner, {})
	if role_key == "hero":
		return units.get("hero", null)
	if role_key == "puppet":
		for unit in Array(units.get("puppet", [])):
			if main._is_live_unit(unit):
				return unit
		return null
	if role_key == "barrier":
		return units.get("barrier", null)
	return null


func _minimal_hero(main, unit_name: String) -> Dictionary:
	var core_index := -1
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			core_index = i
			break
	if core_index < 0:
		_fail("No hero torso fixture found.")
		return {}
	var node: Dictionary = main._topology_component_node(0, "CORE", Vector2(0.5, 0.5), "muscle", core_index)
	return {
		"name": unit_name,
		"unit_name": unit_name,
		"role": "hero",
		"archetype": "custom",
		"special": 0,
		"joint": 0,
		"limb_muscle": 0,
		"muscle": core_index,
		"booster": 0,
		"engine": 0,
		"cooling": 0,
		"module": 0,
		"blank_canvas": false,
		"custom_topology": {"nodes": [node], "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION},
		"slot_payloads": [],
		"purchased_parts": {},
	}


func _minimal_puppet(main, unit_name: String) -> Dictionary:
	var core_index: int = int(main._component_index_by_name("puppet", "muscle", "FLOATING BIT CORE", 95))
	var node: Dictionary = main._topology_component_node(0, "CORE", Vector2(0.5, 0.5), "muscle", core_index)
	return {
		"name": unit_name,
		"unit_name": unit_name,
		"role": "puppet",
		"archetype": "custom",
		"special": 0,
		"joint": 0,
		"limb_muscle": 0,
		"muscle": core_index,
		"booster": 0,
		"engine": 0,
		"cooling": 0,
		"module": 0,
		"blank_canvas": false,
		"custom_topology": {"nodes": [node], "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION},
		"slot_payloads": [],
		"purchased_parts": {},
	}


func _minimal_barrier(main, unit_name: String) -> Dictionary:
	var panel_index: int = int(main._component_index_by_name("barrier", "muscle", "MAZE HARDLIGHT CAGE WALL PANEL", 14))
	return {
		"name": unit_name,
		"unit_name": unit_name,
		"role": "barrier",
		"archetype": "custom",
		"special": 0,
		"joint": 30,
		"limb_muscle": 0,
		"muscle": panel_index,
		"booster": 0,
		"engine": 0,
		"cooling": 5,
		"module": 10,
		"blank_canvas": false,
		"barrier_tiles": [{"index": 0, "muscle": panel_index}],
		"custom_topology": main._default_free_canvas_topology("barrier"),
		"slot_payloads": [],
		"purchased_parts": {},
	}


func _fixture_blueprint_for_role(main, role_key: String) -> Dictionary:
	match role_key:
		"hero":
			return _minimal_hero(main, "Import Probe Hero")
		"puppet":
			return _minimal_puppet(main, "Import Probe Puppet")
		"barrier":
			return _minimal_barrier(main, "Import Probe Barrier")
		_:
			return {}


func _run_case(role_key: String, seat: int) -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit_bp := _fixture_blueprint_for_role(main, role_key)
	if unit_bp.is_empty():
		_fail("No training import fixture for %s." % role_key)
		_cleanup_main(main)
		return
	var note := main._training_blueprint_illegal_note(1, role_key, unit_bp)
	if note != "":
		_fail("%s training import fixture is illegal: %s" % [role_key, note])
		_cleanup_main(main)
		return
	main.training_import_units = [{"role": role_key, "blueprint": unit_bp.duplicate(true)}]
	main.training_import_role_key = role_key
	main.training_import_blueprint = unit_bp.duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(seat)
	main._try_begin_battle_from_scout()
	if main.game_state != MainScene.STATE_BATTLE or main.battle_mode != MainScene.MODE_TRAINING:
		_fail("%s import did not enter training battle for seat %d." % [role_key, seat])
		_cleanup_main(main)
		return
	var owner := 2 if seat == 2 else 1
	var imported = _live_import_for_role(main, owner, role_key)
	if not main._is_live_unit(imported):
		_fail("%s import missing from player %d role slot." % [role_key, owner])
		_cleanup_main(main)
		return
	_cleanup_main(main)


func _init() -> void:
	for role_key in ["hero", "puppet", "barrier"]:
		_run_case(role_key, 1)
	_run_case("hero", 2)
	if not failures.is_empty():
		print("TRAINING_IMPORT_SPAWN_ROLE_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("TRAINING_IMPORT_SPAWN_ROLE_PROBE ok")
	quit(0)
