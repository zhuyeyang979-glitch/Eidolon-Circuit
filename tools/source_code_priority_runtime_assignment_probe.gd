extends SceneTree

const SERVICE_PATH := "res://scripts/services/source_code_priority_service.gd"

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _ids(entries: Array, key: String = "construct_body_id") -> Array:
	var result: Array = []
	for raw_entry in entries:
		if raw_entry is Dictionary:
			result.append(String(Dictionary(raw_entry).get(key, "")))
	return result


func _assignment_pairs(assignments: Array) -> Array:
	var result: Array = []
	for raw_assignment in assignments:
		if raw_assignment is Dictionary:
			var assignment: Dictionary = raw_assignment
			result.append("%s<=%s" % [
				String(assignment.get("construct_body_id", "")),
				String(assignment.get("source_entry_id", "")),
			])
	return result


func _init() -> void:
	var Service = load(SERVICE_PATH)
	var service = Service.new()
	for method_name in [
		"stable_construct_body_id",
		"runtime_assignment",
	]:
		_require(service.has_method(method_name), "SourceCodePriorityService should expose %s for runtime assignment." % method_name)
	if failed:
		quit(1)
		return
	var context := {"owner_id": 1, "role_key": "puppet", "unit_index": 2, "puppet_group_slot": 3}
	_require(service.stable_construct_body_id(context, 0) == "p1:puppet:u2:g3:body0", "Stable body id should include owner, role, unit, puppet slot, and body index.")
	_require(service.stable_construct_body_id(context, 1) == "p1:puppet:u2:g3:body1", "Stable body id should be deterministic per body index.")
	var body_records := [
		{"construct_body_id": service.stable_construct_body_id(context, 0), "blueprint_construct_body_id": "body-a", "body_index": 0},
		{"construct_body_id": service.stable_construct_body_id(context, 1), "blueprint_construct_body_id": "body-b", "body_index": 1},
		{"construct_body_id": service.stable_construct_body_id(context, 2), "blueprint_construct_body_id": "body-c", "body_index": 2},
	]
	var priority_entries := [
		{"entry_id": "body-a:0", "construct_body_id": "body-a", "payload_index": 0, "priority": 1, "source_code_name": "CODE A"},
		{"entry_id": "body-b:1", "construct_body_id": "body-b", "payload_index": 1, "priority": 0, "source_code_name": "CODE B"},
	]
	var source_parts_by_payload := {
		0: {"name": "CODE A", "group_count": 1, "ai": "line", "sequence": ["normal"]},
		1: {"name": "CODE B", "group_count": 2, "ai": "pincer", "sequence": ["armor", "normal"], "source_target_policy": "protect_hero"},
	}
	var result: Dictionary = service.runtime_assignment(priority_entries, source_parts_by_payload, body_records)
	var entries: Array = Array(result.get("entries", []))
	var assignments: Array = Array(result.get("assignments", []))
	_require(_ids(entries, "entry_id") == ["body-b:1", "body-a:0"], "Runtime entries should follow normalized priority order: %s" % str(entries))
	_require(_assignment_pairs(assignments) == [
		"p1:puppet:u2:g3:body1<=body-b:1",
		"p1:puppet:u2:g3:body0<=body-b:1",
		"p1:puppet:u2:g3:body2<=body-a:0",
	], "Assignments should claim carrier first, then stable unassigned bodies: %s" % str(assignments))
	var assignment_by_body: Dictionary = Dictionary(result.get("assignment_by_body", {}))
	_require(String(Dictionary(assignment_by_body.get("p1:puppet:u2:g3:body2", {})).get("source_code_name", "")) == "CODE A", "Later Source Code should receive the remaining body.")
	var live_result: Dictionary = service.runtime_assignment(priority_entries, source_parts_by_payload, body_records, [
		"p1:puppet:u2:g3:body0",
		"p1:puppet:u2:g3:body2",
	])
	var live_assignments: Array = Array(live_result.get("assignments", []))
	_require(_assignment_pairs(live_assignments) == [
		"p1:puppet:u2:g3:body0<=body-a:0",
	], "Destroyed carrier should remove only its own Source Code and preserve survivor order: %s" % str(live_assignments))
	var diagnostics: Array = Array(live_result.get("diagnostics", []))
	var found_destroyed := false
	for raw_diag in diagnostics:
		if raw_diag is Dictionary and String(Dictionary(raw_diag).get("reason", "")) == "carrier_destroyed":
			found_destroyed = true
	_require(found_destroyed, "Runtime diagnostics should explain skipped Source Codes: %s" % str(diagnostics))
	if failed:
		quit(1)
		return
	print("SOURCE_CODE_PRIORITY_RUNTIME_ASSIGNMENT_PROBE ok assignments=%s" % str(_assignment_pairs(assignments)))
	quit(0)
