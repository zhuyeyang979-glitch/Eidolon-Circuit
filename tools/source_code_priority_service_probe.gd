extends SceneTree

const SERVICE_PATH := "res://scripts/services/source_code_priority_service.gd"
const SavedUnitLibraryServiceScript := preload("res://scripts/services/saved_unit_library_service.gd")

var failed := false


func _init() -> void:
	_require(FileAccess.file_exists(SERVICE_PATH), "Missing SourceCodePriorityService script.")
	if failed:
		quit(1)
		return
	var ServiceScript = load(SERVICE_PATH)
	_require(ServiceScript != null, "Cannot load SourceCodePriorityService script.")
	if failed:
		quit(1)
		return
	var service = ServiceScript.new()
	var raw_entries := [
		{"entry_id": "body-a:2", "construct_body_id": "body-a", "payload_index": 2, "source_code_name": "CODE A", "priority": 20},
		{"entry_id": "body-b:0", "construct_body_id": "body-b", "payload_index": 0, "source_code_name": "CODE B", "priority": 5},
		{"entry_id": "body-a:4", "construct_body_id": "body-a", "payload_index": 4, "source_code_name": "CODE C"},
	]
	var normalized: Array = service.normalize(raw_entries)
	_require(_entry_ids(normalized) == ["body-b:0", "body-a:2", "body-a:4"], "Explicit priorities should sort before unranked entries: %s" % str(normalized))
	_require(_priorities(normalized) == [0, 1, 2], "Normalized priorities should be contiguous: %s" % str(normalized))
	_require(int(raw_entries[0].get("priority", -1)) == 20, "Normalization must not mutate source entries.")

	var moved: Array = service.move(normalized, "body-a:4", -1)
	_require(_entry_ids(moved) == ["body-b:0", "body-a:4", "body-a:2"], "Move-up should swap one stable position: %s" % str(moved))
	var clamped: Array = service.move(moved, "body-b:0", -1)
	_require(_entry_ids(clamped) == _entry_ids(moved), "Moving the first entry up should be a no-op.")

	var survivors: Array = service.surviving(moved, ["body-a"])
	_require(_entry_ids(survivors) == ["body-a:4", "body-a:2"], "Destroyed carriers should be removed without reordering surviving Source Codes: %s" % str(survivors))
	_require(_priorities(survivors) == [0, 1], "Surviving Source Codes should be renumbered contiguously.")

	var blueprint := {"role": "puppet", "source_code_priority": moved.duplicate(true)}
	var from_blueprint: Array = service.from_blueprint(blueprint)
	_require(_entry_ids(from_blueprint) == _entry_ids(moved), "Blueprint priority order should be preserved.")
	var json_text := JSON.stringify(blueprint)
	var parsed = JSON.parse_string(json_text)
	_require(parsed is Dictionary, "Priority blueprint should survive JSON serialization.")
	if parsed is Dictionary:
		var round_trip: Array = service.from_blueprint(parsed)
		_require(_entry_ids(round_trip) == _entry_ids(moved), "Saved puppet blueprint should preserve Source Code order after JSON round trip.")
	var library_service = SavedUnitLibraryServiceScript.new()
	var group_payload: Dictionary = library_service.build_save_payload(
		blueprint,
		"puppet",
		7,
		blueprint.duplicate(true),
		"puppet_group",
		[blueprint.duplicate(true), {"role": "puppet", "source_code_priority": survivors.duplicate(true)}]
	)
	var parsed_group = JSON.parse_string(JSON.stringify(group_payload))
	_require(parsed_group is Dictionary, "Puppet-group save payload should survive JSON serialization.")
	if parsed_group is Dictionary:
		var saved_group: Array = Array(Dictionary(parsed_group).get("puppet_group_blueprints", []))
		_require(saved_group.size() == 2, "Puppet-group save should preserve every construct-body blueprint.")
		if saved_group.size() == 2:
			_require(_entry_ids(service.from_blueprint(saved_group[0])) == _entry_ids(moved), "Primary puppet blueprint should preserve Source Code priority.")
			_require(_entry_ids(service.from_blueprint(saved_group[1])) == _entry_ids(survivors), "Surviving puppet blueprint should preserve relative Source Code priority.")

	var malformed: Array = service.normalize([
		"skip",
		{"construct_body_id": "", "payload_index": 0},
		{"construct_body_id": "body-c", "payload_index": 3, "source_code_name": "CODE D"},
	])
	_require(_entry_ids(malformed) == ["body-c:3"], "Malformed entries should be skipped and stable IDs should be derived: %s" % str(malformed))

	if failed:
		quit(1)
		return
	print("SOURCE_CODE_PRIORITY_SERVICE_PROBE ok order=%s survivors=%s" % [str(_entry_ids(moved)), str(_entry_ids(survivors))])
	quit(0)


func _entry_ids(entries: Array) -> Array:
	var result: Array = []
	for raw_entry in entries:
		if raw_entry is Dictionary:
			result.append(String(Dictionary(raw_entry).get("entry_id", "")))
	return result


func _priorities(entries: Array) -> Array:
	var result: Array = []
	for raw_entry in entries:
		if raw_entry is Dictionary:
			result.append(int(Dictionary(raw_entry).get("priority", -1)))
	return result


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
