extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const LegalStarterBlueprintFixture := preload("res://tools/fixtures/legal_starter_blueprint_fixture.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _entry(path: String, role_key: String, unit_name: String, blueprint: Dictionary) -> Dictionary:
	return {
		"unit_library": true,
		"role": role_key,
		"path": path,
		"unit_name": unit_name,
		"blueprint": blueprint,
	}


func _minimal_puppet(main, unit_name: String, has_source_code: bool) -> Dictionary:
	main.editor_role_index = MainScene.ROLE_ORDER.find("puppet")
	var core_index: int = int(main._component_index_by_name("puppet", "muscle", "FLOATING BIT CORE", 95))
	var node: Dictionary = main._topology_component_node(0, "CORE", Vector2(0.5, 0.5), "muscle", core_index)
	return {
		"name": unit_name,
		"unit_name": unit_name,
		"role": "puppet",
		"archetype": "custom",
		"special": 0 if has_source_code else -1,
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


func _minimal_barrier(main, unit_name: String, has_ether: bool) -> Dictionary:
	main.editor_role_index = MainScene.ROLE_ORDER.find("barrier")
	var panel_index: int = int(main._component_index_by_name("barrier", "muscle", "MAZE HARDLIGHT CAGE WALL PANEL", 14))
	var node: Dictionary = main._topology_component_node(0, "PANEL", Vector2(0.5, 0.5), "muscle", panel_index)
	return {
		"name": unit_name,
		"unit_name": unit_name,
		"role": "barrier",
		"archetype": "custom",
		"special": 0 if has_ether else -1,
		"joint": 30,
		"limb_muscle": 0,
		"muscle": panel_index,
		"booster": 0,
		"engine": 0,
		"cooling": 5,
		"module": 10,
		"blank_canvas": false,
		"barrier_tiles": [{"index": 0, "muscle": panel_index}],
		"custom_topology": {"nodes": [node], "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION},
		"slot_payloads": [],
		"purchased_parts": {},
	}


func _illegal_note_for_code(entries: Array, role_key: String, code: String) -> String:
	for raw_entry in entries:
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("role", "")) == role_key:
			var illegal_note := String(Dictionary(raw_entry).get("illegal_note", ""))
			if illegal_note.find(code) >= 0:
				return illegal_note
	return ""


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()

	var legal_hero_a := LegalStarterBlueprintFixture.build(main, "Team Validation Hero A")
	var legal_hero_b := LegalStarterBlueprintFixture.build(main, "Team Validation Hero B")
	_require(not legal_hero_a.is_empty() and not legal_hero_b.is_empty(), "Could not build legal hero fixtures.")
	if failed:
		quit(1)
		return

	var legal_puppet := _minimal_puppet(main, "Team Validation Legal Puppet", true)
	var invalid_puppet := _minimal_puppet(main, "Team Validation Invalid Puppet", false)
	var invalid_barrier := _minimal_barrier(main, "Team Validation Invalid Barrier", false)
	var selection := [
		_entry("probe://team-hero-a", "hero", "Team Validation Hero A", legal_hero_a),
		_entry("probe://team-hero-b", "hero", "Team Validation Hero B", legal_hero_b),
		_entry("probe://team-puppet-legal", "puppet", "Team Validation Legal Puppet", legal_puppet),
		_entry("probe://team-puppet-invalid", "puppet", "Team Validation Invalid Puppet", invalid_puppet),
		_entry("probe://team-barrier-invalid", "barrier", "Team Validation Invalid Barrier", invalid_barrier),
	]
	var normalized: Array = main._team_legality_saved_entries(selection)
	var puppet_note := _illegal_note_for_code(normalized, "puppet", "puppet_source_code_missing")
	var barrier_note := _illegal_note_for_code(normalized, "barrier", "barrier_ether_missing")
	_require(puppet_note.find("puppet_source_code_missing") >= 0, "Team validation entry should preserve puppet_source_code_missing, got %s entries=%s" % [puppet_note, str(normalized)])
	_require(barrier_note.find("barrier_ether_missing") >= 0, "Team validation entry should preserve barrier_ether_missing, got %s entries=%s" % [barrier_note, str(normalized)])
	if failed:
		quit(1)
		return

	var audit: Dictionary = main._team_legality_service().audit(main._team_rule_profile(), normalized)
	_require(not bool(audit.get("roster_ready", true)), "Roster with illegal unit-editor identities should not be team-ready: %s" % str(audit))
	_require(Array(audit.get("roster_blocking_codes", [])).has("illegal_roster_unit"), "Team validation should surface illegal_roster_unit for shared legality failures: %s" % str(audit))
	var summary: Dictionary = main._saved_units_team_legality_summary(selection)
	_require(not bool(summary.get("valid", true)), "Saved-unit team summary should reject shared legality failures: %s" % str(summary))

	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_LEGALITY_TEAM_VALIDATION_PROBE ok puppet=%s barrier=%s" % [puppet_note, barrier_note])
	quit(0)
