extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	await process_frame
	main._ready()
	var hero_bp: Dictionary = _minimal_hero(main, "Multi Training Hero")
	hero_bp["unit_name"] = "Multi Training Hero"
	var puppet_bp: Dictionary = _minimal_puppet(main, "Multi Training Puppet")
	var puppet_bp_b: Dictionary = _minimal_puppet(main, "Multi Training Puppet B")
	var group_bp: Dictionary = puppet_bp.duplicate(true)
	group_bp["unit_name"] = "Multi Training Puppet Group"
	group_bp["save_kind"] = MainScene.SAVE_KIND_PUPPET_GROUP
	group_bp["puppet_group_blueprints"] = [puppet_bp.duplicate(true), puppet_bp_b.duplicate(true)]
	group_bp["group_count"] = 2
	var entries := [
		{"unit_library": true, "role": "hero", "path": "probe://hero", "unit_name": "Multi Training Hero", "blueprint": hero_bp},
		{"unit_library": true, "role": "puppet", "path": "probe://puppet-group", "unit_name": "Multi Training Puppet Group", "save_kind": MainScene.SAVE_KIND_PUPPET_GROUP, "group_count": 2, "blueprint": group_bp, "puppet_group_blueprints": [puppet_bp.duplicate(true), puppet_bp_b.duplicate(true)]},
	]
	var import_intent: Dictionary = main._training_import_intent_from_saved_unit_entries(entries)
	if not bool(import_intent.get("ok", false)):
		var notes: Array = []
		for entry in entries:
			var entry_dict: Dictionary = entry
			var role_key := String(entry_dict.get("role", ""))
			var bp: Dictionary = Dictionary(entry_dict.get("blueprint", {})).duplicate(true)
			var note := main._saved_unit_entry_illegal_note(entry_dict) if main._saved_entry_is_puppet_group(entry_dict) else main._training_blueprint_illegal_note(1, role_key, bp)
			notes.append("%s=%s" % [role_key, note])
		_fail("Saved unit multi-training import intent failed: %s notes=%s" % [String(import_intent.get("error", "")), str(notes)])
		return
	main.training_import_units = Array(import_intent.get("imports", [])).duplicate(true)
	if main.training_import_units.is_empty():
		_fail("Saved unit multi-training import produced no import entries.")
		return
	main.training_import_role_key = String(Dictionary(main.training_import_units[0]).get("role", ""))
	main.training_import_blueprint = Dictionary(Dictionary(main.training_import_units[0]).get("blueprint", {})).duplicate(true)
	if not main._prepare_training_battle_loadouts(false):
		_fail("Saved unit multi-training import failed: %s" % main.training_import_error_note)
		return
	if Array(main.training_test_roster_cache.get("hero", [])).size() != 1 or Array(main.training_test_roster_cache.get("puppet", [])).size() != 1:
		_fail("Multi-training should import all selected units into the training roster cache.")
		return
	var imported_group: Dictionary = Dictionary(Array(main.training_test_roster_cache.get("puppet", []))[0])
	if String(imported_group.get("save_kind", "")) != MainScene.SAVE_KIND_PUPPET_GROUP or Array(imported_group.get("puppet_group_blueprints", [])).size() != 2:
		_fail("Multi-training should preserve puppet group members on the sortie entry.")
		return
	if Array(main.training_test_loadout_cache).size() < 2:
		_fail("Multi-training should keep all selected units in the training sortie cache.")
		return
	if main.training_test_initial_role_cache != "hero":
		_fail("First available hero should be the controllable training starter.")
		return
	print("TRAINING_SAVED_UNIT_MULTI_PROBE ok loadout=%d" % Array(main.training_test_loadout_cache).size())
	quit()


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
