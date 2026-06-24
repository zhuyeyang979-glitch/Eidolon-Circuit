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
