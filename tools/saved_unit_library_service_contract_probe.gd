extends SceneTree

const SERVICE_PATH := "res://scripts/services/saved_unit_library_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const SavedUnitLibraryServiceScript := preload("res://scripts/services/saved_unit_library_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing SavedUnitLibraryService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name SavedUnitLibraryService",
		"signature_from_records",
		"cache_refresh_intent",
		"latest_entry_named",
		"resolve_save_path",
		"build_save_payload",
		"readback_status",
		"entry_from_payload",
		"rejected_entry_from_payload",
		"entries_from_records",
	]:
		if service_source.find(token) < 0:
			_fail("SavedUnitLibraryService missing token: %s" % token)
			return
	for forbidden in ["FileAccess", "DirAccess", "JSON.parse_string", "Button", "extends Control", "Control.new", "_set_save_unit_failure_feedback"]:
		if service_source.find(forbidden) >= 0:
			_fail("SavedUnitLibraryService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const SavedUnitLibraryService = preload(\"res://scripts/services/saved_unit_library_service.gd\")",
		"var saved_unit_library_service: SavedUnitLibraryService",
		"saved_unit_library_service = SavedUnitLibraryService.new()",
		"saved_unit_library_service.signature_from_records",
		"saved_unit_library_service.cache_refresh_intent",
		"saved_unit_library_service.latest_entry_named",
		"saved_unit_library_service.resolve_save_path",
		"saved_unit_library_service.build_save_payload",
		"saved_unit_library_service.readback_status",
		"saved_unit_library_service.entry_from_payload",
		"saved_unit_library_service.rejected_entry_from_payload",
		"saved_unit_library_service.entries_from_records",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate saved-unit library service token: %s" % token)
			return
	var service = SavedUnitLibraryServiceScript.new()
	var signature := service.signature_from_records([
		{"path": "user://a.json", "mtime": 10, "size": 20},
		"skip-me",
		{"path": "user://b.json", "mtime": 11, "size": 21},
	])
	if signature != "user://a.json:10:20|user://b.json:11:21":
		_fail("signature_from_records returned unexpected signature: %s" % signature)
	var same_records := [{"path": "user://a.json", "mtime": 10, "size": 20}]
	var same_signature := service.signature_from_records(same_records)
	var deferred_intent: Dictionary = service.cache_refresh_intent(false, false, true, true, "", same_records)
	if bool(deferred_intent.get("should_refresh", true)) or String(deferred_intent.get("action", "")) != "skip_deferred":
		_fail("cache_refresh_intent should skip deferred scans without force/check_disk: %s" % str(deferred_intent))
	var clean_intent: Dictionary = service.cache_refresh_intent(false, false, false, false, same_signature, same_records)
	if bool(clean_intent.get("should_refresh", true)) or String(clean_intent.get("action", "")) != "skip_clean":
		_fail("cache_refresh_intent should skip clean cache without disk check: %s" % str(clean_intent))
	var same_intent: Dictionary = service.cache_refresh_intent(false, true, false, false, same_signature, same_records)
	if bool(same_intent.get("should_refresh", true)) or String(same_intent.get("action", "")) != "skip_same_signature":
		_fail("cache_refresh_intent should skip unchanged disk signature: %s" % str(same_intent))
	var dirty_intent: Dictionary = service.cache_refresh_intent(false, false, false, true, same_signature, same_records)
	if not bool(dirty_intent.get("should_refresh", false)) or String(dirty_intent.get("action", "")) != "refresh":
		_fail("cache_refresh_intent should refresh dirty cache: %s" % str(dirty_intent))
	var force_intent: Dictionary = service.cache_refresh_intent(true, false, true, false, same_signature, same_records)
	if not bool(force_intent.get("should_refresh", false)):
		_fail("cache_refresh_intent should refresh when forced: %s" % str(force_intent))
	var entries := [
		{"path": "old-hero.json", "role": "hero", "unit_name": "Unit A", "mtime": 10},
		{"path": "new-puppet.json", "role": "puppet", "unit_name": "Unit A", "mtime": 30},
		{"path": "new-hero.json", "role": "hero", "unit_name": "Unit A", "mtime": 20},
		{"path": "trimmed.json", "role": "hero", "unit_name": "  Unit B  ", "mtime": 40},
		"skip-me",
	]
	var hero_latest: Dictionary = service.latest_entry_named(entries, "Unit A", "hero")
	if String(hero_latest.get("path", "")) != "new-hero.json":
		_fail("latest_entry_named should pick latest matching role by mtime: %s" % str(hero_latest))
	var any_latest: Dictionary = service.latest_entry_named(entries, "Unit A")
	if String(any_latest.get("path", "")) != "new-puppet.json":
		_fail("latest_entry_named without role should pick latest matching name.")
	if String(service.latest_entry_named(entries, "Unit B", "hero").get("path", "")) != "trimmed.json":
		_fail("latest_entry_named should compare stripped names.")
	if not service.latest_entry_named(entries, "", "hero").is_empty():
		_fail("latest_entry_named should reject empty names.")
	if service.resolve_save_path("user://requested.json", false, "user://source.json", true, "user://match.json", "user://generated.json") != "user://requested.json":
		_fail("resolve_save_path should prefer requested path.")
	if service.resolve_save_path("", false, "user://source.json", true, "user://match.json", "user://generated.json") != "user://source.json":
		_fail("resolve_save_path should overwrite source path when allowed.")
	if service.resolve_save_path("", false, "user://source.json", false, "user://match.json", "user://generated.json") != "user://match.json":
		_fail("resolve_save_path should use matching entry path when source is unavailable.")
	if service.resolve_save_path("", true, "user://source.json", true, "user://match.json", "user://generated.json") != "user://generated.json":
		_fail("resolve_save_path should use generated path for save-as.")
	var payload: Dictionary = service.build_save_payload(
		{"unit_id": "id-1", "unit_name": "Unit A", "name": "Fallback", "team_color": {"r": 1}},
		"hero",
		7,
		{"safe": true}
	)
	if int(payload.get("schema_version", -1)) != 7 or String(payload.get("unit_role", "")) != "hero" or String(payload.get("unit_name", "")) != "Unit A":
		_fail("build_save_payload returned unexpected metadata: %s" % str(payload))
	if not (payload.get("blueprint", {}) is Dictionary) or not bool(Dictionary(payload.get("blueprint", {})).get("safe", false)):
		_fail("build_save_payload should include delegated safe blueprint.")
	var context := {
		"role_order": ["hero", "puppet", "barrier"],
		"role_names": {"hero": "HERO", "puppet": "PUPPET", "barrier": "BARRIER"},
	}
	var restored_entry: Dictionary = service.entry_from_payload(
		"user://unit.json",
		{
			"unit_id": "id-entry",
			"unit_name": "Entry Unit",
			"unit_role": "puppet",
			"blueprint": {"role": "hero", "name": "Before Restore", "restore_marker": "yes"},
		},
		context,
		Callable(self, "_restore_for_probe"),
		Callable(self, "_apply_pose_for_probe")
	)
	if restored_entry.is_empty() or String(restored_entry.get("path", "")) != "user://unit.json" or String(restored_entry.get("role", "")) != "puppet":
		_fail("entry_from_payload should build a typed unit-library entry: %s" % str(restored_entry))
	var restored_bp: Dictionary = Dictionary(restored_entry.get("blueprint", {}))
	if String(restored_bp.get("role", "")) != "puppet" or String(restored_bp.get("unit_id", "")) != "id-entry":
		_fail("entry_from_payload should apply payload identity metadata: %s" % str(restored_bp))
	if not bool(restored_bp.get("restored", false)) or not bool(restored_bp.get("pose_applied", false)):
		_fail("entry_from_payload should use restore and apply-pose callbacks: %s" % str(restored_bp))
	if not service.entry_from_payload("bad.json", {"unit_role": "invalid", "blueprint": {}}, context, Callable(self, "_restore_for_probe"), Callable()).is_empty():
		_fail("entry_from_payload should reject roles outside context role_order.")
	var rejected_entry: Dictionary = service.rejected_entry_from_payload(
		"user://bad.json",
		{"unit_name": "Bad Unit", "unit_role": "alien", "blueprint": {"name": "Fallback Bad"}},
		"bad topology",
		context,
		Callable(self, "_restore_for_probe")
	)
	if not bool(rejected_entry.get("canonical_rejected", false)) or String(rejected_entry.get("role", "")) != "hero":
		_fail("rejected_entry_from_payload should produce canonical rejected fallback entries: %s" % str(rejected_entry))
	if String(rejected_entry.get("load_rejection_reason", "")) != "INVALID: stored data rejected: bad topology":
		_fail("rejected_entry_from_payload should preserve rejection reason.")
	var loaded_entries: Array = service.entries_from_records([
		{"path": "load-a.json", "mtime": 1, "size": 2},
		"skip-me",
		{"path": "empty.json", "mtime": 3, "size": 4},
		{"path": "load-b.json", "mtime": 5, "size": 6},
	], Callable(self, "_load_entry_for_probe"))
	if loaded_entries.size() != 2:
		_fail("entries_from_records should skip invalid records and empty loaded entries: %s" % str(loaded_entries))
	if String(Dictionary(loaded_entries[0]).get("path", "")) != "load-a.json" or int(Dictionary(loaded_entries[1]).get("mtime", 0)) != 5 or int(Dictionary(loaded_entries[1]).get("size", 0)) != 6:
		_fail("entries_from_records should stamp mtime/size from records: %s" % str(loaded_entries))
	var ok_status: Dictionary = service.readback_status({"path": "unit.json"}, "")
	if not bool(ok_status.get("ok", false)):
		_fail("readback_status should accept non-rejected readback.")
	var empty_status: Dictionary = service.readback_status({}, "")
	if bool(empty_status.get("ok", true)) or String(empty_status.get("reason", "")) == "":
		_fail("readback_status should reject empty readback with default reason.")
	var reason_status: Dictionary = service.readback_status({}, "bad json")
	if bool(reason_status.get("ok", true)) or String(reason_status.get("reason", "")) != "bad json":
		_fail("readback_status should preserve explicit rejection reason.")
	var rejected_status: Dictionary = service.readback_status({"canonical_rejected": true, "load_rejection_reason": "invalid topology"}, "")
	if bool(rejected_status.get("ok", true)) or String(rejected_status.get("reason", "")) != "invalid topology":
		_fail("readback_status should reject canonical-rejected entries.")
	print("SAVED_UNIT_LIBRARY_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _restore_for_probe(value):
	if value is Dictionary:
		var restored: Dictionary = Dictionary(value).duplicate(true)
		restored["restored"] = true
		return restored
	return value


func _apply_pose_for_probe(unit_bp: Dictionary) -> void:
	unit_bp["pose_applied"] = true


func _load_entry_for_probe(path: String):
	if path == "empty.json":
		return {}
	return {"path": path, "unit_name": path.get_basename()}
