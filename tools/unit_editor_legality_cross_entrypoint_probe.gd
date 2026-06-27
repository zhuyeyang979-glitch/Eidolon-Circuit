extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const LegalStarterBlueprintFixture := preload("res://tools/fixtures/legal_starter_blueprint_fixture.gd")

var failed := false
var created_paths: Array = []


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _has_code(report: Dictionary, code: String) -> bool:
	return Array(report.get("blocking_codes", [])).has(code)


func _cleanup() -> void:
	for raw_path in created_paths:
		var path := String(raw_path)
		if path != "" and FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _write_payload(path: String, payload: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not write fixture: %s" % path)
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	created_paths.append(path)
	return true


func _replace_topology_node_part(main, source: Dictionary, node_index: int, replacement: int) -> Dictionary:
	var candidate: Dictionary = source.duplicate(true)
	var topology: Dictionary = Dictionary(candidate.get("custom_topology", {})).duplicate(true)
	var nodes: Array = Array(topology.get("nodes", [])).duplicate(true)
	if node_index < 0 or node_index >= nodes.size() or not (nodes[node_index] is Dictionary):
		return {}
	var node: Dictionary = Dictionary(nodes[node_index]).duplicate(true)
	var slot_key := String(node.get("slot", node.get("slot_key", "")))
	var part: Dictionary = main._selected_component("hero", slot_key, replacement)
	node["part_index"] = replacement
	node["part_name"] = String(part.get("name", ""))
	nodes[node_index] = node
	topology["nodes"] = nodes
	candidate["custom_topology"] = topology
	return candidate


func _socket_kind_variant(source: Dictionary) -> Dictionary:
	var candidate: Dictionary = source.duplicate(true)
	var topology: Dictionary = Dictionary(candidate.get("custom_topology", {})).duplicate(true)
	var edges: Array = Array(topology.get("edges", [])).duplicate(true)
	if edges.is_empty() or not (edges[0] is Dictionary):
		return {}
	var edge: Dictionary = Dictionary(edges[0]).duplicate(true)
	edge["a_socket"] = "center"
	edges[0] = edge
	topology["edges"] = edges
	candidate["custom_topology"] = topology
	return candidate


func _socket_size_variant(main, source: Dictionary) -> Dictionary:
	var topology: Dictionary = source.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", []))
	for node_index in range(nodes.size()):
		if not (nodes[node_index] is Dictionary):
			continue
		var node: Dictionary = nodes[node_index]
		if main._topology_node_is_torso("hero", node, source):
			continue
		var slot_key := String(node.get("slot", node.get("slot_key", "")))
		var current_index := int(node.get("part_index", -1))
		for replacement in range(main._catalog_for("hero", slot_key).size()):
			if replacement == current_index:
				continue
			var candidate := _replace_topology_node_part(main, source, node_index, replacement)
			if candidate.is_empty():
				continue
			var report: Dictionary = main._unit_editor_legality_report("hero", candidate)
			if _has_code(report, "socket_part_too_large") and not _has_code(report, "socket_kind_not_owned"):
				return candidate
	return {}


func _manufacturer_variant(main, source: Dictionary) -> Dictionary:
	var topology: Dictionary = source.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", []))
	for node_index in range(nodes.size()):
		if not (nodes[node_index] is Dictionary):
			continue
		var node: Dictionary = nodes[node_index]
		var slot_key := String(node.get("slot", node.get("slot_key", "")))
		var current_index := int(node.get("part_index", -1))
		var current_part: Dictionary = main._selected_component("hero", slot_key, current_index)
		var current_maker := String(current_part.get("maker", current_part.get("manufacturer", ""))).strip_edges()
		for replacement in range(main._catalog_for("hero", slot_key).size()):
			if replacement == current_index:
				continue
			var part: Dictionary = main._selected_component("hero", slot_key, replacement)
			var maker := String(part.get("maker", part.get("manufacturer", ""))).strip_edges()
			if maker == "" or current_maker == "" or maker == current_maker:
				continue
			var candidate := _replace_topology_node_part(main, source, node_index, replacement)
			if candidate.is_empty():
				continue
			var report: Dictionary = main._unit_editor_legality_report("hero", candidate)
			if _has_code(report, "construct_body_mixed_manufacturer") and not _has_code(report, "socket_part_too_large") and not _has_code(report, "socket_kind_not_owned"):
				return candidate
	return {}


func _unit_payload(main, blueprint: Dictionary, unit_name: String) -> Dictionary:
	var saved_bp: Dictionary = main._unit_blueprint_for_library("hero", blueprint.duplicate(true))
	saved_bp["unit_name"] = unit_name
	saved_bp["name"] = unit_name
	return main._saved_unit_library_service().build_save_payload(
		saved_bp,
		"hero",
		MainScene.SAVED_UNIT_SCHEMA_VERSION,
		main._json_safe_value(saved_bp),
		MainScene.SAVE_KIND_SINGLE_UNIT
	)


func _team_payload_from_player(main, player_id: int, team_name: String) -> Dictionary:
	return {
		"schema_version": MainScene.SAVED_TEAM_SCHEMA_VERSION,
		"team_name": team_name,
		"rule_id": String(main._team_rule_profile().get("rule_id", "")),
		"match_format": "light",
		"roster_cap": int(main._current_roster_cap()),
		"sortie_cap": int(main._current_sortie_cap()),
		"slots": main._team_export_slots(player_id),
	}


func _replace_first_hero_team_slot(main, payload: Dictionary, blueprint: Dictionary) -> Dictionary:
	var next_payload := payload.duplicate(true)
	var slots: Array = Array(next_payload.get("slots", [])).duplicate(true)
	for i in range(slots.size()):
		if not (slots[i] is Dictionary):
			continue
		var slot: Dictionary = Dictionary(slots[i]).duplicate(true)
		if String(slot.get("role", "")) != "hero":
			continue
		var saved_bp: Dictionary = main._unit_blueprint_for_library("hero", blueprint.duplicate(true))
		slot["blueprint"] = main._json_safe_value(saved_bp)
		slots[i] = slot
		next_payload["slots"] = slots
		return next_payload
	_fail("Legal team fixture had no hero slot to replace.")
	return next_payload


func _assert_variant_across_entrypoints(main, variant_key: String, expected_code: String, blueprint: Dictionary) -> void:
	var report: Dictionary = main._unit_editor_legality_report("hero", blueprint)
	_require(_has_code(report, expected_code), "%s fixture should expose %s in the shared report: %s" % [variant_key, expected_code, str(report)])
	var note: String = main._training_blueprint_illegal_note(1, "hero", blueprint)
	_require(note.contains(expected_code), "%s training/save gate should preserve %s, got %s" % [variant_key, expected_code, note])
	if not note.contains(expected_code):
		return

	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = blueprint.duplicate(true)
	main.editor_source_saved_unit_path = ""
	var rejected_save_path := "%s/cross_entry_%s_rejected.json" % [MainScene.SAVED_UNITS_DIR, variant_key]
	if FileAccess.file_exists(rejected_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(rejected_save_path))
	var save_result: String = main._save_editor_current_unit_to_library_named("Cross Entry %s" % variant_key, rejected_save_path, true)
	_require(save_result == "", "%s editor save should reject %s, got %s" % [variant_key, expected_code, save_result])
	_require(not FileAccess.file_exists(rejected_save_path), "%s editor save wrote an illegal unit file." % variant_key)

	var stored_path := "%s/cross_entry_%s_stored.json" % [MainScene.SAVED_UNITS_DIR, variant_key]
	main._ensure_saved_units_dir()
	_write_payload(stored_path, _unit_payload(main, blueprint, "Stored %s" % variant_key))
	var stored_entry: Dictionary = main._unit_library_entry_from_file(stored_path)
	_require(not stored_entry.is_empty() and not bool(stored_entry.get("canonical_rejected", false)), "%s fixture should remain canonical storage even though it is battle-illegal: %s" % [variant_key, str(stored_entry)])
	var stored_note: String = main._saved_unit_entry_illegal_note(stored_entry)
	_require(stored_note.contains(expected_code), "%s saved-unit readback should preserve %s, got %s" % [variant_key, expected_code, stored_note])

	var normalized_entries: Array = main._team_legality_saved_entries([stored_entry])
	_require(not normalized_entries.is_empty(), "%s saved entry should reach team normalization." % variant_key)
	if not normalized_entries.is_empty():
		var normalized_note := String(Dictionary(normalized_entries[0]).get("illegal_note", ""))
		_require(normalized_note.contains(expected_code), "%s team normalization should preserve %s, got %s" % [variant_key, expected_code, normalized_note])

	main.blueprints[1]["hero"] = [blueprint.duplicate(true)]
	main.ai_roster_stats_cache.clear()
	_require(not main._sortie_entry_is_battle_legal(1, {"role": "hero", "index": 0}, false), "%s direct battle entry should reject %s." % [variant_key, expected_code])

	main.editor_match_format = "light"
	main._legalize_ai_player_roster(1, true)
	var legal_team_payload := _team_payload_from_player(main, 1, "Cross Entry %s Team" % variant_key)
	var illegal_team_payload := _replace_first_hero_team_slot(main, legal_team_payload, blueprint)
	var team_path := "user://saved_teams/cross_entry_%s_team.json" % variant_key
	main._ensure_saved_teams_dir()
	_write_payload(team_path, illegal_team_payload)
	_require(not main._load_saved_team_to_current_roster(team_path), "%s saved-team load should reject %s." % [variant_key, expected_code])
	_require(not main._import_editor_team(team_path), "%s editor team import should reject %s." % [variant_key, expected_code])

	main._legalize_ai_player_roster(1, true)
	var heroes: Array = Array(main.blueprints[1].get("hero", [])).duplicate(true)
	_require(not heroes.is_empty(), "%s formal roster fixture should include a hero." % variant_key)
	if not heroes.is_empty():
		heroes[0] = blueprint.duplicate(true)
		main.blueprints[1]["hero"] = heroes
		main.ai_roster_stats_cache.clear()
		var battle_summary: Dictionary = main._team_battle_entry_summary(1)
		_require(not bool(battle_summary.get("valid", true)), "%s formal battle summary should reject %s: %s" % [variant_key, expected_code, str(battle_summary)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var legal_bp := LegalStarterBlueprintFixture.build(main, "Cross Entrypoint Legal Starter")
	_require(not legal_bp.is_empty(), "Could not build legal starter fixture.")
	if legal_bp.is_empty():
		_cleanup()
		quit(1)
		return
	var variants := [
		{"key": "socket_size", "code": "socket_part_too_large", "blueprint": _socket_size_variant(main, legal_bp)},
		{"key": "socket_kind", "code": "socket_kind_not_owned", "blueprint": _socket_kind_variant(legal_bp)},
		{"key": "manufacturer", "code": "construct_body_mixed_manufacturer", "blueprint": _manufacturer_variant(main, legal_bp)},
	]
	for raw_variant in variants:
		var variant: Dictionary = raw_variant
		var blueprint: Dictionary = Dictionary(variant.get("blueprint", {}))
		_require(not blueprint.is_empty(), "Could not build %s topology fixture." % String(variant.get("key", "")))
		if not blueprint.is_empty():
			_assert_variant_across_entrypoints(main, String(variant.get("key", "")), String(variant.get("code", "")), blueprint)
	_cleanup()
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_LEGALITY_CROSS_ENTRYPOINT_PROBE ok variants=%d" % variants.size())
	quit(0)
