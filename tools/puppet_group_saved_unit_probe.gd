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
	var puppet_a: Dictionary = _minimal_puppet(main, "Probe Puppet A")
	var puppet_b: Dictionary = _minimal_puppet(main, "Probe Puppet B")
	var selection := [
		{"unit_library": true, "role": "puppet", "path": "probe://pa", "unit_name": "Probe Puppet A", "blueprint": puppet_a},
		{"unit_library": true, "role": "puppet", "path": "probe://pb", "unit_name": "Probe Puppet B", "blueprint": puppet_b},
	]
	var save_path := main._save_puppet_group_from_saved_unit_selection("Probe Puppet Group", selection)
	if save_path == "" or not FileAccess.file_exists(save_path):
		_fail("Puppet group save did not create a file. hint=%s" % (main.saved_unit_hint_label.text if main.saved_unit_hint_label != null else ""))
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not (parsed is Dictionary):
		_fail("Puppet group JSON is damaged.")
		return
	var payload: Dictionary = parsed
	if String(payload.get("save_kind", "")) != MainScene.SAVE_KIND_PUPPET_GROUP or String(payload.get("unit_role", "")) != "puppet":
		_fail("Puppet group payload missing save_kind/unit_role: %s" % str(payload))
		return
	if Array(payload.get("puppet_group_blueprints", [])).size() != 2:
		_fail("Puppet group payload should contain two member blueprints.")
		return
	main._invalidate_saved_unit_library_cache()
	var entry := main._unit_library_entry_from_file(save_path)
	if entry.is_empty() or not main._saved_entry_is_puppet_group(entry):
		_fail("Saved library did not read puppet group entry: %s" % str(entry))
		return
	if int(entry.get("group_count", 0)) != 2:
		_fail("Puppet group entry should expose group_count=2.")
		return
	main.training_import_units = main._training_imports_from_saved_unit_entries([entry])
	if main.training_import_units.is_empty() or String(Dictionary(main.training_import_units[0]).get("save_kind", "")) != MainScene.SAVE_KIND_PUPPET_GROUP:
		_fail("Training import did not preserve puppet group marker.")
		return
	main.training_import_role_key = String(Dictionary(main.training_import_units[0]).get("role", ""))
	main.training_import_blueprint = Dictionary(Dictionary(main.training_import_units[0]).get("blueprint", {})).duplicate(true)
	main.ai_battle_seat = 1
	if not main._prepare_training_battle_loadouts(false):
		_fail("Puppet group training loadout failed: %s" % main.training_import_error_note)
		return
	var roster: Array = Array(main.training_test_roster_cache.get("puppet", []))
	if roster.size() != 1:
		_fail("Puppet group should remain one sortie roster entry before deployment.")
		return
	var group_bp: Dictionary = Dictionary(roster[0])
	if Array(group_bp.get("puppet_group_blueprints", [])).size() != 2:
		_fail("Roster puppet group lost member blueprints.")
		return
	if not main._configure_training_sides_for_seat():
		_fail("Puppet group training side assignment failed: %s" % main.training_import_error_note)
		return
	main._begin_battle(MainScene.MODE_TRAINING, true)
	main._summon_role(1, "puppet", true, true)
	var live_group: Array = Array(main.active_units[1].get("puppet", []))
	if live_group.size() != 2:
		_fail("Puppet group deployment should expand to two live puppets, got %d." % live_group.size())
		return
	for i in range(live_group.size()):
		var unit = live_group[i]
		if not main._is_live_unit(unit):
			_fail("Expanded puppet %d is not live." % i)
			return
		if int(unit.get_meta("puppet_group_slot", -1)) != i or int(unit.get_meta("puppet_group_size", -1)) != 2:
			_fail("Expanded puppet metadata mismatch.")
			return
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("PUPPET_GROUP_SAVED_UNIT_PROBE ok path=%s" % save_path)
	quit(0)


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
