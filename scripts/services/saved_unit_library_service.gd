extends RefCounted
class_name SavedUnitLibraryService


func signature_from_records(records: Array) -> String:
	var parts: Array[String] = []
	for raw_record in records:
		if not (raw_record is Dictionary):
			continue
		var record: Dictionary = raw_record
		parts.append("%s:%d:%d" % [String(record.get("path", "")), int(record.get("mtime", 0)), int(record.get("size", 0))])
	return "|".join(parts)


func cache_refresh_intent(force: bool, check_disk: bool, scan_deferred: bool, dirty: bool, old_signature: String, records: Array) -> Dictionary:
	if scan_deferred and not force and not check_disk:
		return {"action": "skip_deferred", "should_refresh": false, "signature": old_signature}
	if not force and not check_disk and not dirty:
		return {"action": "skip_clean", "should_refresh": false, "signature": old_signature}
	var signature := signature_from_records(records)
	if not force and not dirty and signature == old_signature:
		return {"action": "skip_same_signature", "should_refresh": false, "signature": signature}
	return {"action": "refresh", "should_refresh": true, "signature": signature}


func latest_entry_named(entries: Array, unit_name: String, role_key: String = "") -> Dictionary:
	var clean_name := unit_name.strip_edges()
	if clean_name == "":
		return {}
	var best_entry := {}
	var best_time := -1
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		if role_key != "" and String(entry.get("role", "")) != role_key:
			continue
		if String(entry.get("unit_name", "")).strip_edges() != clean_name:
			continue
		var modified := int(entry.get("mtime", 0))
		if modified >= best_time:
			best_time = modified
			best_entry = entry.duplicate(true)
	return best_entry


func resolve_save_path(requested_path: String, save_as_new: bool, source_path: String, source_exists: bool, matching_entry_path: String, generated_path: String) -> String:
	if requested_path != "":
		return requested_path
	if not save_as_new:
		if source_path != "" and source_exists:
			return source_path
		if matching_entry_path != "":
			return matching_entry_path
	return generated_path


func build_save_payload(unit_bp: Dictionary, role_key: String, schema_version, safe_blueprint, save_kind: String = "single_unit", safe_puppet_group_blueprints: Array = []) -> Dictionary:
	var payload := {
		"schema_version": schema_version,
		"save_kind": save_kind if save_kind != "" else "single_unit",
		"unit_id": String(unit_bp.get("unit_id", "")),
		"unit_name": String(unit_bp.get("unit_name", unit_bp.get("name", ""))),
		"unit_role": role_key,
		"team_color": unit_bp.get("team_color", {}),
		"blueprint": safe_blueprint,
	}
	if String(payload.get("save_kind", "")) == "puppet_group":
		payload["unit_role"] = "puppet"
		payload["puppet_group_blueprints"] = safe_puppet_group_blueprints.duplicate(true)
	return payload


func readback_status(readback_entry: Dictionary, rejection_reason: String) -> Dictionary:
	if readback_entry.is_empty():
		return {
			"ok": false,
			"reason": rejection_reason if rejection_reason != "" else "saved file cannot be read back by the unit library",
		}
	if bool(readback_entry.get("canonical_rejected", false)):
		return {
			"ok": false,
			"reason": rejection_reason if rejection_reason != "" else String(readback_entry.get("load_rejection_reason", "saved file cannot be read back by the unit library")),
		}
	return {"ok": true, "reason": ""}


func entry_from_payload(path: String, payload: Dictionary, context: Dictionary, restore_fn: Callable, apply_pose_fn: Callable) -> Dictionary:
	if not restore_fn.is_valid():
		return {}
	var save_kind := String(payload.get("save_kind", "single_unit"))
	if save_kind == "":
		save_kind = "single_unit"
	var role_key := String(payload.get("unit_role", "hero"))
	var role_order: Array = Array(context.get("role_order", []))
	if not role_order.has(role_key):
		return {}
	var group_blueprints: Array = []
	if save_kind == "puppet_group":
		if role_key != "puppet":
			return {}
		group_blueprints = _restored_puppet_group_blueprints(payload, restore_fn, apply_pose_fn)
		if group_blueprints.is_empty():
			return {}
	if not (payload.get("blueprint", {}) is Dictionary):
		if save_kind != "puppet_group":
			return {}
	var unit_bp: Dictionary = {}
	if payload.get("blueprint", {}) is Dictionary:
		unit_bp = Dictionary(restore_fn.call(payload.get("blueprint", {}))).duplicate(true)
	elif not group_blueprints.is_empty():
		unit_bp = Dictionary(group_blueprints[0]).duplicate(true)
	unit_bp["role"] = role_key
	unit_bp["unit_id"] = String(payload.get("unit_id", unit_bp.get("unit_id", "")))
	unit_bp["unit_name"] = String(payload.get("unit_name", unit_bp.get("unit_name", unit_bp.get("name", ""))))
	unit_bp["name"] = String(unit_bp.get("unit_name", unit_bp.get("name", _role_name_from_context(context, role_key))))
	if apply_pose_fn.is_valid():
		apply_pose_fn.call(unit_bp)
	var entry := {
		"unit_library": true,
		"path": path,
		"role": role_key,
		"index": -1,
		"save_kind": save_kind,
		"blueprint": unit_bp,
		"unit_name": String(unit_bp.get("unit_name", unit_bp.get("name", ""))),
	}
	if save_kind == "puppet_group":
		unit_bp["save_kind"] = "puppet_group"
		unit_bp["puppet_group_blueprints"] = group_blueprints.duplicate(true)
		unit_bp["group_count"] = group_blueprints.size()
		entry["blueprint"] = unit_bp
		entry["puppet_group_blueprints"] = group_blueprints.duplicate(true)
		entry["group_count"] = group_blueprints.size()
	return entry


func rejected_entry_from_payload(path: String, payload: Dictionary, rejection_reason: String, context: Dictionary, restore_fn: Callable) -> Dictionary:
	var unit_bp := {}
	if payload.get("blueprint", {}) is Dictionary and restore_fn.is_valid():
		unit_bp = Dictionary(restore_fn.call(payload.get("blueprint", {}))).duplicate(true)
	var role_key := String(payload.get("unit_role", unit_bp.get("role", "hero")))
	var role_order: Array = Array(context.get("role_order", []))
	if not role_order.has(role_key):
		role_key = "hero"
	var unit_name := String(payload.get("unit_name", unit_bp.get("unit_name", unit_bp.get("name", path.get_file()))))
	return {
		"unit_library": true,
		"path": path,
		"role": role_key,
		"index": -1,
		"save_kind": String(payload.get("save_kind", "single_unit")),
		"blueprint": unit_bp,
		"unit_name": unit_name,
		"canonical_rejected": true,
		"load_rejection_reason": "INVALID: stored data rejected: %s" % rejection_reason,
	}


func entries_from_records(records: Array, load_entry_fn: Callable) -> Array:
	var entries: Array = []
	if not load_entry_fn.is_valid():
		return entries
	for raw_record in records:
		if not (raw_record is Dictionary):
			continue
		var record: Dictionary = raw_record
		var path := String(record.get("path", ""))
		var entry = load_entry_fn.call(path)
		if not (entry is Dictionary):
			continue
		var entry_dict: Dictionary = entry
		if entry_dict.is_empty():
			continue
		entry_dict["mtime"] = int(record.get("mtime", 0))
		entry_dict["size"] = int(record.get("size", 0))
		entries.append(entry_dict)
	return entries


func _role_name_from_context(context: Dictionary, role_key: String) -> String:
	var role_names: Dictionary = Dictionary(context.get("role_names", {}))
	return String(role_names.get(role_key, role_key))


func _restored_puppet_group_blueprints(payload: Dictionary, restore_fn: Callable, apply_pose_fn: Callable) -> Array:
	var restored: Array = []
	for raw_bp in Array(payload.get("puppet_group_blueprints", [])):
		if not (raw_bp is Dictionary):
			continue
		var member: Dictionary = Dictionary(restore_fn.call(raw_bp)).duplicate(true)
		member["role"] = "puppet"
		member["save_kind"] = "single_unit"
		member.erase("puppet_group_blueprints")
		if apply_pose_fn.is_valid():
			apply_pose_fn.call(member)
		restored.append(member)
	return restored
