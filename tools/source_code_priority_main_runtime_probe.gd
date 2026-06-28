extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _source_code_indices(main, count: int, group_count: int = -1) -> Array:
	var result: Array = []
	var catalog: Array = main._catalog_for("puppet", "special")
	for i in range(catalog.size()):
		if catalog[i] is Dictionary and String(Dictionary(catalog[i]).get("kind", "")) == "code":
			if group_count >= 0 and int(Dictionary(catalog[i]).get("group_count", 1)) != group_count:
				continue
			result.append(i)
			if result.size() >= count:
				return result
	return result


func _source_code_index_by_ai(main, ai_kind: String) -> int:
	var catalog: Array = main._catalog_for("puppet", "special")
	for i in range(catalog.size()):
		if not (catalog[i] is Dictionary):
			continue
		var part: Dictionary = catalog[i]
		if String(part.get("kind", "")) == "code" and String(part.get("ai", "")) == ai_kind:
			return i
	return -1


func _source_code_part(main, index: int) -> Dictionary:
	var catalog: Array = main._catalog_for("puppet", "special")
	if index < 0 or index >= catalog.size() or not (catalog[index] is Dictionary):
		return {}
	return Dictionary(catalog[index])


func _torso_index(main) -> int:
	var catalog: Array = main._catalog_for("puppet", "muscle")
	for i in range(catalog.size()):
		if catalog[i] is Dictionary and main._component_is_torso(Dictionary(catalog[i])):
			return i
	return -1


func _pairs(assignments: Array) -> Array:
	var result: Array = []
	for raw_assignment in assignments:
		if raw_assignment is Dictionary:
			var assignment: Dictionary = raw_assignment
			result.append("%s<=%s" % [
				String(assignment.get("construct_body_id", "")),
				String(assignment.get("source_entry_id", "")),
			])
	return result


func _diag_reasons(diagnostics: Array) -> Array:
	var result: Array = []
	for raw_diag in diagnostics:
		if raw_diag is Dictionary:
			result.append(String(Dictionary(raw_diag).get("reason", "")))
	return result


func _blueprint(torso: int, code_a: int, code_b: int) -> Dictionary:
	return {
		"role": "puppet",
		"name": "Runtime Source Assignment Probe",
		"blank_canvas": false,
		"custom_topology": {
			"nodes": [
				{"id": 0, "slot": "muscle", "part_index": torso, "label": "Carrier A"},
				{"id": 1, "slot": "muscle", "part_index": torso, "label": "Carrier B"},
				{"id": 2, "slot": "muscle", "part_index": torso, "label": "Worker C"},
			],
			"edges": [],
		},
		"slot_payloads": [
			{"kind": "special", "special": code_a, "software_kind": "code", "torso_node": 0},
			{"kind": "special", "special": code_b, "software_kind": "code", "torso_node": 1},
		],
		"source_code_priority": [
			{"entry_id": "torso:0:0", "construct_body_id": "torso:0", "payload_index": 0, "priority": 1},
			{"entry_id": "torso:1:1", "construct_body_id": "torso:1", "payload_index": 1, "priority": 0},
		],
	}


func _selected_source_blueprint(torso: int, selected_code: int, trailing_code: int) -> Dictionary:
	return {
		"role": "puppet",
		"name": "Runtime Source Selected Stats Probe",
		"blank_canvas": false,
		"custom_topology": {
			"nodes": [
				{"id": 0, "slot": "muscle", "part_index": torso, "label": "Carrier A"},
				{"id": 1, "slot": "muscle", "part_index": torso, "label": "Worker B"},
				{"id": 2, "slot": "muscle", "part_index": torso, "label": "Worker C"},
			],
			"edges": [],
		},
		"slot_payloads": [
			{"kind": "special", "special": selected_code, "software_kind": "code", "torso_node": 0},
			{"kind": "special", "special": trailing_code, "software_kind": "code", "torso_node": 1},
		],
		"source_code_priority": [
			{"entry_id": "torso:0:0", "construct_body_id": "torso:0", "payload_index": 0, "priority": 0},
			{"entry_id": "torso:1:1", "construct_body_id": "torso:1", "payload_index": 1, "priority": 1},
		],
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ui_language = "en"
	var codes := _source_code_indices(main, 2, 2)
	var torso := _torso_index(main)
	var line_code := _source_code_index_by_ai(main, "line")
	var figure8_code := _source_code_index_by_ai(main, "figure8")
	_require(codes.size() >= 2, "Probe needs two puppet Source Codes.")
	_require(torso >= 0, "Probe needs one puppet torso.")
	_require(line_code >= 0 and figure8_code >= 0, "Probe needs distinct line and figure8 Source Codes.")
	if failed:
		quit(1)
		return
	var unit_bp := _blueprint(torso, int(codes[0]), int(codes[1]))
	var stats: Dictionary = main._compute_unit_stats(1, "puppet", 2, unit_bp)
	var body_records: Array = Array(stats.get("source_code_runtime_body_records", []))
	var entries: Array = Array(stats.get("source_code_runtime_entries", []))
	var assignments: Array = Array(stats.get("source_code_runtime_assignments", []))
	var diagnostics: Array = Array(stats.get("source_code_runtime_diagnostics", []))
	_require(body_records.size() == 3, "Puppet stats should materialize three runtime construct-body records: %s" % str(body_records))
	if failed:
		quit(1)
		return
	_require(String(Dictionary(body_records[0]).get("construct_body_id", "")) == "p1:puppet:u2:body0", "Runtime body IDs should be stable before scene spawn: %s" % str(body_records))
	_require(String(Dictionary(entries[0]).get("entry_id", "")) == "torso:1:1", "Runtime source entries should follow Source Code priority: %s" % str(entries))
	_require(_pairs(assignments) == [
		"p1:puppet:u2:body1<=torso:1:1",
		"p1:puppet:u2:body0<=torso:1:1",
		"p1:puppet:u2:body2<=torso:0:0",
	], "Stats should expose deterministic body-to-code assignments: %s" % str(assignments))
	var runtime_nodes: Array = Array(stats.get("runtime_topology_nodes", []))
	_require(runtime_nodes.size() >= 2 and String(Dictionary(runtime_nodes[1]).get("construct_body_id", "")) == "p1:puppet:u2:body1", "Runtime topology nodes should carry matching construct-body IDs: %s" % str(runtime_nodes))
	var group_stats := stats.duplicate(true)
	main._apply_source_code_runtime_assignment_stats(group_stats, 1, "puppet", 2, unit_bp, 0)
	var group_body_records: Array = Array(group_stats.get("source_code_runtime_body_records", []))
	_require(group_body_records.size() == 3 and String(Dictionary(group_body_records[0]).get("construct_body_id", "")) == "p1:puppet:u2:g0:body0", "Puppet spawn slots should namespace runtime body IDs: %s" % str(group_body_records))
	_require(not _diag_reasons(diagnostics).has("carrier_missing") and not _diag_reasons(diagnostics).has("carrier_destroyed"), "Fresh spawn stats should not reject live carriers: %s" % str(diagnostics))
	var selected_bp := _selected_source_blueprint(torso, line_code, figure8_code)
	var selected_stats: Dictionary = main._compute_unit_stats(1, "puppet", 3, selected_bp)
	var selected_part := _source_code_part(main, line_code)
	var selected_assignment: Dictionary = Dictionary(selected_stats.get("source_code_runtime_selected_assignment", {}))
	var selected_rules: Dictionary = Dictionary(selected_stats.get("source_rules", {}))
	var selected_default_rule: Dictionary = Dictionary(selected_rules.get("default", {}))
	_require(String(selected_assignment.get("source_entry_id", "")) == "torso:0:0", "Runtime stats should mark the Source Code assigned to the primary body as selected: %s" % str(selected_stats.get("source_code_runtime_assignments", [])))
	_require(String(selected_stats.get("ai", "")) == String(selected_part.get("ai", "")), "Runtime stats should use the selected Source Code AI instead of the trailing payload AI: %s" % str(selected_stats))
	_require(Array(selected_stats.get("sequence", [])) == Array(selected_part.get("sequence", ["normal"])), "Runtime stats should use the selected Source Code sequence/default: %s" % str(selected_stats.get("sequence", [])))
	_require(String(selected_default_rule.get("move", "")) == "approach", "Runtime source rules should be rebuilt for the selected line Source Code, not the trailing figure8 code: %s" % str(selected_rules))
	_require(int(selected_stats.get("module_sequence_limit", 0)) == int(selected_part.get("module_sequence_limit", 0)) and int(selected_stats.get("condition_slots", 0)) == int(selected_part.get("condition_slots", 0)), "Runtime stats should use selected Source Code limits: %s" % str(selected_stats))
	if failed:
		quit(1)
		return
	print("SOURCE_CODE_PRIORITY_MAIN_RUNTIME_PROBE ok assignments=%s" % str(_pairs(assignments)))
	quit(0)
