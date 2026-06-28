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
		if not (catalog[i] is Dictionary):
			continue
		var part: Dictionary = catalog[i]
		if String(part.get("kind", "")) != "code":
			continue
		if group_count >= 0 and int(part.get("group_count", 1)) != group_count:
			continue
		result.append(i)
		if result.size() >= count:
			return result
	return result


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
		"name": "Runtime Source Rebuild Probe",
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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ui_language = "en"
	var codes := _source_code_indices(main, 2, 2)
	var torso := _torso_index(main)
	_require(codes.size() >= 2, "Probe needs two two-body Source Codes.")
	_require(torso >= 0, "Probe needs one puppet torso.")
	_require(main.has_method("_rebuild_source_code_runtime_assignments_for_unit"), "Main should expose a Source Code runtime rebuild helper.")
	if failed:
		quit(1)
		return
	var unit_bp := _blueprint(torso, int(codes[0]), int(codes[1]))
	var surviving_code_part := _source_code_part(main, int(codes[0]))
	var stats: Dictionary = main._compute_unit_stats(1, "puppet", 2, unit_bp)
	var unit = main._create_unit(1, "puppet", stats, "Source Rebuild Probe", 1.0, 0.0)
	unit.set_meta("hardware_fault_construct_body_destroyed", {"p1:puppet:u2:body1": true})
	main._rebuild_source_code_runtime_assignments_for_unit(unit)
	var assignments: Array = Array(unit.stats.get("source_code_runtime_assignments", []))
	var diagnostics: Array = Array(unit.stats.get("source_code_runtime_diagnostics", []))
	_require(_pairs(assignments) == [
		"p1:puppet:u2:body0<=torso:0:0",
		"p1:puppet:u2:body2<=torso:0:0",
	], "Destroyed carrier should remove only its Source Code and let survivors keep operating: %s" % str(assignments))
	_require(_diag_reasons(diagnostics).has("carrier_destroyed"), "Rebuild diagnostics should explain the removed carrier: %s" % str(diagnostics))
	_require(Dictionary(unit.stats.get("assignment_by_body", {})).is_empty(), "Probe guard: legacy assignment_by_body should not be written at top level.")
	_require(String(Dictionary(unit.stats.get("source_code_runtime_selected_assignment", {})).get("source_entry_id", "")) == "torso:0:0", "Rebuild should select the surviving Source Code for the primary body: %s" % str(unit.stats.get("source_code_runtime_selected_assignment", {})))
	_require(String(unit.stats.get("ai", "")) == String(surviving_code_part.get("ai", "")), "Rebuild should update runtime AI from the surviving Source Code: %s" % str(unit.stats))
	_require(String(Dictionary(Dictionary(unit.stats.get("source_rules", {})).get("default", {})).get("move", "")) == "approach", "Rebuild should refresh source rules for the surviving Source Code: %s" % str(unit.stats.get("source_rules", {})))
	var hooked_stats: Dictionary = main._compute_unit_stats(1, "puppet", 2, unit_bp)
	var hooked_unit = main._create_unit(1, "puppet", hooked_stats, "Source Rebuild Hook Probe", 1.0, 0.0)
	main._consume_hardware_fault_destruction_for_target(hooked_unit, {
		"destruction_intent": "destroy_construct_body",
		"target_construct_body_id": "p1:puppet:u2:body1",
		"target_hardware_node_id": 1,
	}, 2)
	var hooked_assignments: Array = Array(hooked_unit.stats.get("source_code_runtime_assignments", []))
	_require(_pairs(hooked_assignments) == [
		"p1:puppet:u2:body0<=torso:0:0",
		"p1:puppet:u2:body2<=torso:0:0",
	], "Construct-body destruction consume should rebuild Source Code assignment stats: %s" % str(hooked_assignments))
	_require(Array(hooked_unit.stats.get("source_code_runtime_destroyed_construct_body_ids", [])) == ["p1:puppet:u2:body1"], "Consumed construct-body destruction should persist destroyed Source Code body IDs: %s" % str(hooked_unit.stats))
	_require(String(Dictionary(hooked_unit.stats.get("source_code_runtime_selected_assignment", {})).get("source_entry_id", "")) == "torso:0:0" and String(hooked_unit.stats.get("ai", "")) == String(surviving_code_part.get("ai", "")), "Construct-body destruction consume should refresh selected Source Code behavior: %s" % str(hooked_unit.stats))
	if failed:
		quit(1)
		return
	print("SOURCE_CODE_PRIORITY_DESTRUCTION_REBUILD_PROBE ok assignments=%s diagnostics=%s" % [str(_pairs(assignments)), str(_diag_reasons(diagnostics))])
	quit(0)
