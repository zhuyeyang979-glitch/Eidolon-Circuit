extends RefCounted
class_name SourceCodePriorityService


func normalize(raw_entries: Array) -> Array:
	var prepared: Array = []
	for source_index in range(raw_entries.size()):
		if not (raw_entries[source_index] is Dictionary):
			continue
		var entry: Dictionary = Dictionary(raw_entries[source_index]).duplicate(true)
		var construct_body_id := String(entry.get("construct_body_id", "")).strip_edges()
		var payload_index := int(entry.get("payload_index", -1))
		if construct_body_id == "" or payload_index < 0:
			continue
		var entry_id := String(entry.get("entry_id", "")).strip_edges()
		if entry_id == "":
			entry_id = "%s:%d" % [construct_body_id, payload_index]
		entry["entry_id"] = entry_id
		entry["construct_body_id"] = construct_body_id
		entry["payload_index"] = payload_index
		entry["_source_index"] = source_index
		entry["_has_priority"] = entry.has("priority")
		prepared.append(entry)
	prepared.sort_custom(_priority_less)
	for i in range(prepared.size()):
		var entry: Dictionary = prepared[i]
		entry.erase("_source_index")
		entry.erase("_has_priority")
		entry["priority"] = i
		prepared[i] = entry
	return prepared


func move(raw_entries: Array, entry_id: String, direction: int) -> Array:
	var ordered := normalize(raw_entries)
	var current_index := -1
	for i in range(ordered.size()):
		if String(Dictionary(ordered[i]).get("entry_id", "")) == entry_id:
			current_index = i
			break
	if current_index < 0 or direction == 0:
		return ordered
	var target_index := clampi(current_index + signi(direction), 0, ordered.size() - 1)
	if target_index == current_index:
		return ordered
	var current = ordered[current_index]
	ordered[current_index] = ordered[target_index]
	ordered[target_index] = current
	return _renumber(ordered)


func surviving(raw_entries: Array, live_construct_body_ids: Array) -> Array:
	var live_ids := {}
	for raw_id in live_construct_body_ids:
		var body_id := String(raw_id).strip_edges()
		if body_id != "":
			live_ids[body_id] = true
	var result: Array = []
	for raw_entry in normalize(raw_entries):
		var entry: Dictionary = raw_entry
		if bool(live_ids.get(String(entry.get("construct_body_id", "")), false)):
			result.append(entry.duplicate(true))
	return _renumber(result)


func from_blueprint(blueprint) -> Array:
	if not (blueprint is Dictionary):
		return []
	var raw_entries = Dictionary(blueprint).get("source_code_priority", [])
	return normalize(Array(raw_entries)) if raw_entries is Array else []


func stable_construct_body_id(context: Dictionary, body_index: int) -> String:
	var owner_id := int(context.get("owner_id", context.get("player_id", 0)))
	var role_key := String(context.get("role_key", context.get("role", "puppet"))).strip_edges()
	if role_key == "":
		role_key = "puppet"
	var unit_index := int(context.get("unit_index", context.get("sortie_index", 0)))
	var group_slot := int(context.get("puppet_group_slot", context.get("group_slot", -1)))
	var prefix := "p%d:%s:u%d" % [owner_id, role_key, unit_index]
	if group_slot >= 0:
		prefix += ":g%d" % group_slot
	return "%s:body%d" % [prefix, maxi(0, body_index)]


func runtime_assignment(raw_entries: Array, source_parts_by_payload_index: Dictionary, body_records: Array, live_construct_body_ids: Array = []) -> Dictionary:
	var records := _normalized_body_records(body_records)
	var live_ids := _runtime_live_ids(records, live_construct_body_ids)
	var ordered_entries := normalize(raw_entries)
	var body_by_blueprint_id := {}
	var body_by_runtime_id := {}
	for raw_record in records:
		var record: Dictionary = raw_record
		body_by_runtime_id[String(record.get("construct_body_id", ""))] = record
		var blueprint_id := String(record.get("blueprint_construct_body_id", "")).strip_edges()
		if blueprint_id != "":
			body_by_blueprint_id[blueprint_id] = record
	var runtime_entries: Array = []
	var diagnostics: Array = []
	for raw_entry in ordered_entries:
		var entry: Dictionary = Dictionary(raw_entry).duplicate(true)
		var carrier_key := String(entry.get("construct_body_id", "")).strip_edges()
		var carrier: Dictionary = Dictionary(body_by_blueprint_id.get(carrier_key, body_by_runtime_id.get(carrier_key, {})))
		if carrier.is_empty():
			diagnostics.append(_runtime_diag(entry, "", "carrier_missing"))
			continue
		var runtime_body_id := String(carrier.get("construct_body_id", ""))
		if not bool(live_ids.get(runtime_body_id, false)):
			diagnostics.append(_runtime_diag(entry, runtime_body_id, "carrier_destroyed"))
			continue
		var payload_index := int(entry.get("payload_index", -1))
		var source_part := _source_part_for_payload(source_parts_by_payload_index, payload_index)
		if source_part.is_empty():
			diagnostics.append(_runtime_diag(entry, runtime_body_id, "invalid_payload"))
			continue
		entry["runtime_construct_body_id"] = runtime_body_id
		entry["blueprint_construct_body_id"] = carrier_key
		entry["source_part"] = source_part.duplicate(true)
		entry["source_code_name"] = String(entry.get("source_code_name", source_part.get("name", "SOURCE CODE")))
		entry["group_count"] = maxi(0, int(source_part.get("group_count", entry.get("group_count", 1))))
		for key in ["ai", "sequence", "source_rules", "source_target_policy", "source_attack_preference", "module_sequence_limit", "condition_slots"]:
			if source_part.has(key):
				entry[key] = source_part[key]
		runtime_entries.append(entry)
	var assignments: Array = []
	var assignment_by_body := {}
	for raw_entry in runtime_entries:
		var entry: Dictionary = raw_entry
		var capacity := maxi(0, int(entry.get("group_count", 1)))
		if capacity <= 0:
			diagnostics.append(_runtime_diag(entry, String(entry.get("runtime_construct_body_id", "")), "capacity_zero"))
			continue
		var candidates := _candidate_body_ids_for_entry(entry, records, live_ids)
		var claimed := 0
		for raw_body_id in candidates:
			if claimed >= capacity:
				break
			var body_id := String(raw_body_id)
			if bool(assignment_by_body.has(body_id)):
				continue
			var assignment := _assignment_for(entry, body_id)
			assignments.append(assignment)
			assignment_by_body[body_id] = assignment
			claimed += 1
		if claimed <= 0:
			diagnostics.append(_runtime_diag(entry, String(entry.get("runtime_construct_body_id", "")), "no_eligible_body"))
	for raw_record in records:
		var body_id := String(Dictionary(raw_record).get("construct_body_id", ""))
		if bool(live_ids.get(body_id, false)) and not assignment_by_body.has(body_id):
			diagnostics.append({"construct_body_id": body_id, "reason": "unassigned_body"})
	return {
		"body_records": records,
		"entries": runtime_entries,
		"assignments": assignments,
		"assignment_by_body": assignment_by_body,
		"diagnostics": diagnostics,
	}


func _priority_less(a: Dictionary, b: Dictionary) -> bool:
	var a_ranked := bool(a.get("_has_priority", false))
	var b_ranked := bool(b.get("_has_priority", false))
	if a_ranked != b_ranked:
		return a_ranked
	if a_ranked:
		var a_priority := int(a.get("priority", 0))
		var b_priority := int(b.get("priority", 0))
		if a_priority != b_priority:
			return a_priority < b_priority
	return int(a.get("_source_index", 0)) < int(b.get("_source_index", 0))


func _renumber(entries: Array) -> Array:
	var result: Array = []
	for i in range(entries.size()):
		if not (entries[i] is Dictionary):
			continue
		var entry: Dictionary = Dictionary(entries[i]).duplicate(true)
		entry["priority"] = result.size()
		result.append(entry)
	return result


func _normalized_body_records(raw_records: Array) -> Array:
	var records: Array = []
	for i in range(raw_records.size()):
		if not (raw_records[i] is Dictionary):
			continue
		var record: Dictionary = Dictionary(raw_records[i]).duplicate(true)
		var runtime_id := String(record.get("construct_body_id", "")).strip_edges()
		if runtime_id == "":
			continue
		record["construct_body_id"] = runtime_id
		record["body_index"] = int(record.get("body_index", records.size()))
		var blueprint_id := String(record.get("blueprint_construct_body_id", record.get("saved_construct_body_id", ""))).strip_edges()
		if blueprint_id == "":
			blueprint_id = runtime_id
		record["blueprint_construct_body_id"] = blueprint_id
		records.append(record)
	records.sort_custom(_body_record_less)
	return records


func _body_record_less(a: Dictionary, b: Dictionary) -> bool:
	var a_index := int(a.get("body_index", 0))
	var b_index := int(b.get("body_index", 0))
	if a_index != b_index:
		return a_index < b_index
	return String(a.get("construct_body_id", "")) < String(b.get("construct_body_id", ""))


func _runtime_live_ids(records: Array, live_construct_body_ids: Array) -> Dictionary:
	var live_ids := {}
	if live_construct_body_ids.is_empty():
		for raw_record in records:
			var body_id := String(Dictionary(raw_record).get("construct_body_id", ""))
			if body_id != "":
				live_ids[body_id] = true
		return live_ids
	for raw_id in live_construct_body_ids:
		var body_id := String(raw_id).strip_edges()
		if body_id != "":
			live_ids[body_id] = true
	return live_ids


func _source_part_for_payload(source_parts_by_payload_index: Dictionary, payload_index: int) -> Dictionary:
	var raw_part = source_parts_by_payload_index.get(payload_index, source_parts_by_payload_index.get(str(payload_index), {}))
	return Dictionary(raw_part) if raw_part is Dictionary else {}


func _runtime_diag(entry: Dictionary, runtime_body_id: String, reason: String) -> Dictionary:
	return {
		"entry_id": String(entry.get("entry_id", "")),
		"payload_index": int(entry.get("payload_index", -1)),
		"construct_body_id": runtime_body_id,
		"blueprint_construct_body_id": String(entry.get("construct_body_id", "")),
		"reason": reason,
	}


func _candidate_body_ids_for_entry(entry: Dictionary, records: Array, live_ids: Dictionary) -> Array:
	var result: Array = []
	var carrier_id := String(entry.get("runtime_construct_body_id", ""))
	if carrier_id != "" and bool(live_ids.get(carrier_id, false)):
		result.append(carrier_id)
	for raw_record in records:
		var body_id := String(Dictionary(raw_record).get("construct_body_id", ""))
		if body_id == "" or body_id == carrier_id:
			continue
		if bool(live_ids.get(body_id, false)):
			result.append(body_id)
	return result


func _assignment_for(entry: Dictionary, body_id: String) -> Dictionary:
	return {
		"construct_body_id": body_id,
		"source_entry_id": String(entry.get("entry_id", "")),
		"source_payload_index": int(entry.get("payload_index", -1)),
		"source_code_name": String(entry.get("source_code_name", "SOURCE CODE")),
		"source_priority": int(entry.get("priority", 0)),
		"runtime_source_construct_body_id": String(entry.get("runtime_construct_body_id", "")),
		"source_ai": String(entry.get("ai", "")),
		"source_target_policy": String(entry.get("source_target_policy", "")),
		"source_attack_preference": String(entry.get("source_attack_preference", "")),
		"reason": "assigned",
	}
