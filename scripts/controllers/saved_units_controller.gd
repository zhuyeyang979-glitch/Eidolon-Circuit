extends RefCounted
class_name SavedUnitsController

var main_ref: Object
var state_store
var dirty_graph
var cache
var profiler
var refresh_count := 0


func bind(main: Object, store, graph, derived_cache, hot_profiler) -> void:
	main_ref = main
	state_store = store
	dirty_graph = graph
	cache = derived_cache
	profiler = hot_profiler


func mark_dirty(reason: String = "saved_units") -> void:
	refresh_count += 1
	if state_store != null:
		state_store.mark_dirty("saved_units", 1, reason)
	if dirty_graph != null:
		dirty_graph.mark("saved_units", 1, reason)
	if profiler != null:
		profiler.count("saved_units.mark_dirty")


func summary_line() -> String:
	return "saved ctrl dirty:%d" % refresh_count


func signature_from_records(records: Array) -> String:
	var parts: Array[String] = []
	for raw_record in records:
		if not (raw_record is Dictionary):
			continue
		var record: Dictionary = raw_record
		parts.append("%s:%d:%d" % [String(record.get("path", "")), int(record.get("mtime", 0)), int(record.get("size", 0))])
	return "|".join(parts)


func filtered_cache_key(filter_key: String, library_signature: String) -> String:
	return "%s|%s" % [filter_key, library_signature]


func entry_path(entry: Dictionary) -> String:
	return String(entry.get("path", entry.get("unit_id", entry.get("unit_name", ""))))


func filter_entries(entries: Array, filter_key: String, illegal_note_fn: Callable = Callable()) -> Array:
	var filtered: Array = []
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		if _entry_matches_filter(entry, filter_key, illegal_note_fn):
			filtered.append(entry)
	return filtered


func absolute_index_for_card(card_index: int, page: int, page_size: int) -> int:
	return page * maxi(1, page_size) + card_index


func page_for_focus_path(entries: Array, path: String, page_size: int) -> Dictionary:
	if path == "":
		return {"found": false, "selected_index": -1, "page": 0}
	var safe_page_size := maxi(1, page_size)
	for i in range(entries.size()):
		if not (entries[i] is Dictionary):
			continue
		if entry_path(Dictionary(entries[i])) == path:
			return {
				"found": true,
				"selected_index": i,
				"page": int(floor(float(i) / float(safe_page_size))),
			}
	return {"found": false, "selected_index": -1, "page": 0}


func selection_state_for_filter(filter_key: String) -> Dictionary:
	return {
		"saved_unit_filter": filter_key,
		"saved_unit_page": 0,
		"saved_unit_selected_index": -1,
		"saved_unit_hovered_path": "",
		"saved_unit_hovered_index": -1,
		"saved_unit_detail_path": "",
	}


func selection_state_for_card(card_index: int, page: int, page_size: int, entries: Array) -> Dictionary:
	var absolute_index := absolute_index_for_card(card_index, page, page_size)
	if absolute_index < 0 or absolute_index >= entries.size() or not (entries[absolute_index] is Dictionary):
		return {"valid": false, "absolute_index": absolute_index}
	var entry: Dictionary = entries[absolute_index]
	return {
		"valid": true,
		"saved_unit_selected_index": absolute_index,
		"saved_unit_hovered_path": entry_path(entry),
		"saved_unit_hovered_index": absolute_index,
	}


func hover_state_for_card(card_index: int, page: int, page_size: int, entries: Array, current_hovered_path: String, current_hovered_index: int) -> Dictionary:
	var absolute_index := absolute_index_for_card(card_index, page, page_size)
	if absolute_index < 0 or absolute_index >= entries.size() or not (entries[absolute_index] is Dictionary):
		return {"valid": false, "changed": false, "absolute_index": absolute_index}
	var entry: Dictionary = entries[absolute_index]
	var path := entry_path(entry)
	var changed := current_hovered_index != absolute_index or current_hovered_path != path
	return {
		"valid": true,
		"changed": changed,
		"entry": entry,
		"saved_unit_hovered_path": path,
		"saved_unit_hovered_index": absolute_index,
	}


func selected_entries(entries: Array, selected_paths: Array) -> Array:
	var selected: Array = []
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		if selected_paths.has(entry_path(entry)):
			selected.append(entry)
	return selected


func delete_candidates(entries: Array, selected_paths: Array, selected_index: int, fallback_selected_entry: Dictionary = {}) -> Array:
	var candidates := selected_entries(entries, selected_paths)
	if not candidates.is_empty():
		return candidates
	if not fallback_selected_entry.is_empty():
		return [fallback_selected_entry]
	if selected_index >= 0 and selected_index < entries.size() and entries[selected_index] is Dictionary:
		return [Dictionary(entries[selected_index])]
	return []


func delete_request_intent(candidates: Array) -> Dictionary:
	var paths: Array = []
	var names: Array = []
	for raw_entry in candidates:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var path := entry_path(entry)
		if path == "" or paths.has(path):
			continue
		paths.append(path)
		names.append(String(entry.get("unit_name", path.get_file())))
	var summary := ", ".join(names.slice(0, mini(names.size(), 4)))
	if names.size() > 4:
		summary += "..."
	return {
		"valid": not paths.is_empty(),
		"pending_delete_paths": paths,
		"names": names,
		"summary": summary,
	}


func toggle_selection_state(entry: Dictionary, selected_paths: Array, illegal_note: String = "") -> Dictionary:
	if bool(entry.get("canonical_rejected", false)):
		return {"valid": false, "reason": illegal_note}
	var path := entry_path(entry)
	if path == "":
		return {"valid": false, "reason": "missing_path"}
	var next_paths := selected_paths.duplicate()
	if next_paths.has(path):
		next_paths.erase(path)
	else:
		next_paths.append(path)
	return {
		"valid": true,
		"saved_unit_selected_paths": next_paths,
		"saved_unit_detail_path": "",
		"toggled_path": path,
	}


func page_action_state(action_key: String, page: int, page_size: int, entry_count: int, selected_index: int, selected_paths: Array, selected_entry: Dictionary = {}) -> Dictionary:
	var safe_page_size := maxi(1, page_size)
	var max_page := maxi(0, int(ceil(float(maxi(0, entry_count)) / float(safe_page_size))) - 1)
	match action_key:
		"prev":
			return {"valid": true, "action": "page", "saved_unit_page": maxi(0, page - 1)}
		"next":
			return {"valid": true, "action": "page", "saved_unit_page": mini(max_page, page + 1)}
		"clear":
			return {"valid": true, "action": "clear_selection", "saved_unit_selected_paths": []}
		"toggle":
			if selected_entry.is_empty():
				return {"valid": false, "action": "toggle"}
			var toggle_state := toggle_selection_state(selected_entry, selected_paths)
			toggle_state["action"] = "toggle"
			return toggle_state
		_:
			return {"valid": false, "action": action_key}


func _entry_matches_filter(entry: Dictionary, filter_key: String, illegal_note_fn: Callable) -> bool:
	match filter_key:
		"all":
			return true
		"invalid":
			if illegal_note_fn.is_valid():
				return String(illegal_note_fn.call(entry)) != ""
			return String(entry.get("load_rejection_reason", "")) != "" or bool(entry.get("canonical_rejected", false))
		_:
			return String(entry.get("role", "hero")) == filter_key
