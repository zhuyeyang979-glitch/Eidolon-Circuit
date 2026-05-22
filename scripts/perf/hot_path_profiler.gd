extends RefCounted
class_name HotPathProfiler

const MAX_HISTORY := 180
const MAX_INTERACTION_SAMPLES := 240

var frame_index := 0
var last_frame_usec := 0
var max_frame_usec := 0
var counters := {}
var values := {}
var _scope_stack := []
var _scope_totals := {}
var _scope_counts := {}
var _frame_history := []
var _interaction_samples := {}
var _interaction_scope_totals := {}
var _active_interactions := {}


func begin_frame(_now_usec: int = 0) -> void:
	frame_index += 1
	last_frame_usec = 0
	_scope_stack.clear()
	_scope_totals.clear()
	_scope_counts.clear()
	_frame_history.append(Time.get_ticks_usec())
	if _frame_history.size() > MAX_HISTORY:
		_frame_history.pop_front()


func end_frame() -> void:
	if _frame_history.is_empty():
		return
	var started := int(_frame_history[_frame_history.size() - 1])
	last_frame_usec = Time.get_ticks_usec() - started
	max_frame_usec = max(max_frame_usec, last_frame_usec)
	for interaction_name in _active_interactions.keys():
		record_interaction_sample(String(interaction_name), last_frame_usec, scope_stats())


func scope_begin(name: String) -> void:
	_scope_stack.append({"name": name, "started": Time.get_ticks_usec()})


func scope_end(name: String = "") -> void:
	if _scope_stack.is_empty():
		return
	var entry: Dictionary = _scope_stack.pop_back()
	var scope_name := String(entry.get("name", ""))
	if name != "" and scope_name != name:
		scope_name = "%s->%s" % [scope_name, name]
	var elapsed := Time.get_ticks_usec() - int(entry.get("started", Time.get_ticks_usec()))
	_scope_totals[scope_name] = int(_scope_totals.get(scope_name, 0)) + elapsed
	_scope_counts[scope_name] = int(_scope_counts.get(scope_name, 0)) + 1
	for interaction_name in _active_interactions.keys():
		var bucket: Dictionary = _interaction_scope_totals.get(interaction_name, {})
		bucket[scope_name] = int(bucket.get(scope_name, 0)) + elapsed
		_interaction_scope_totals[interaction_name] = bucket


func count(name: String, amount: int = 1) -> void:
	counters[name] = int(counters.get(name, 0)) + amount


func record_value(name: String, value: Variant) -> void:
	values[name] = value


func begin_interaction(name: String) -> void:
	if name == "":
		return
	_active_interactions[name] = Time.get_ticks_usec()


func end_interaction(name: String) -> void:
	if name == "":
		return
	if not _active_interactions.has(name):
		return
	var started := int(_active_interactions.get(name, Time.get_ticks_usec()))
	var had_frame_samples := _interaction_samples.has(name) and not Array(_interaction_samples.get(name, [])).is_empty()
	_active_interactions.erase(name)
	if not had_frame_samples:
		record_interaction_sample(name, Time.get_ticks_usec() - started, scope_stats())


func record_interaction_sample(name: String, frame_usec: int, scopes: Dictionary = {}) -> void:
	if name == "":
		return
	var samples: Array = _interaction_samples.get(name, [])
	samples.append(maxi(0, frame_usec))
	while samples.size() > MAX_INTERACTION_SAMPLES:
		samples.pop_front()
	_interaction_samples[name] = samples
	if not scopes.is_empty():
		var bucket: Dictionary = _interaction_scope_totals.get(name, {})
		for scope_name in scopes.keys():
			var scope_data: Dictionary = Dictionary(scopes[scope_name])
			bucket[scope_name] = int(bucket.get(scope_name, 0)) + int(scope_data.get("usec", 0))
		_interaction_scope_totals[name] = bucket


func scope_stats() -> Dictionary:
	var result := {}
	for name in _scope_totals.keys():
		result[name] = {
			"usec": int(_scope_totals[name]),
			"count": int(_scope_counts.get(name, 0)),
		}
	return result


func interaction_stats(name: String) -> Dictionary:
	var samples: Array = _interaction_samples.get(name, [])
	if samples.is_empty():
		return {"count": 0, "p95_usec": 0, "max_usec": 0, "hot_scope": "", "hot_scope_usec": 0}
	var sorted_samples := samples.duplicate()
	sorted_samples.sort()
	var p95_index := clampi(int(ceil(float(sorted_samples.size()) * 0.95)) - 1, 0, sorted_samples.size() - 1)
	var max_usec := 0
	for raw_value in samples:
		max_usec = maxi(max_usec, int(raw_value))
	var hot_scope := ""
	var hot_scope_usec := 0
	var scopes: Dictionary = _interaction_scope_totals.get(name, {})
	for scope_name in scopes.keys():
		var elapsed := int(scopes[scope_name])
		if elapsed > hot_scope_usec:
			hot_scope_usec = elapsed
			hot_scope = String(scope_name)
	return {
		"count": samples.size(),
		"p95_usec": int(sorted_samples[p95_index]),
		"max_usec": max_usec,
		"hot_scope": hot_scope,
		"hot_scope_usec": hot_scope_usec,
	}


func interaction_hot_scopes(name: String, limit: int = 5, exclude_parent_scopes: bool = true) -> Array:
	var scopes: Dictionary = _interaction_scope_totals.get(name, {})
	var rows: Array = []
	for scope_name in scopes.keys():
		var scope_text := String(scope_name)
		if exclude_parent_scopes:
			var has_child := false
			var child_prefix := scope_text + "."
			for other_name in scopes.keys():
				if String(other_name).begins_with(child_prefix):
					has_child = true
					break
			if has_child:
				continue
		rows.append({
			"name": scope_text,
			"usec": int(scopes[scope_name]),
		})
	rows.sort_custom(func(a, b): return int(a.get("usec", 0)) > int(b.get("usec", 0)))
	if limit > 0 and rows.size() > limit:
		rows = rows.slice(0, limit)
	return rows


func interaction_summary_line(name: String) -> String:
	var stats := interaction_stats(name)
	var leaf_scopes := interaction_hot_scopes(name, 3, true)
	var leaf_texts: Array = []
	for row in leaf_scopes:
		leaf_texts.append("%s %.2fms" % [String(row.get("name", "")), float(row.get("usec", 0)) / 1000.0])
	var leaf_suffix := ""
	if not leaf_texts.is_empty():
		var joined_leaf_text := ""
		for i in range(leaf_texts.size()):
			if i > 0:
				joined_leaf_text += ", "
			joined_leaf_text += String(leaf_texts[i])
		leaf_suffix = " leaf[%s]" % joined_leaf_text
	return ("%s n=%d p95 %.2fms max %.2fms hot %s %.2fms" % [
		name,
		int(stats.get("count", 0)),
		float(stats.get("p95_usec", 0)) / 1000.0,
		float(stats.get("max_usec", 0)) / 1000.0,
		String(stats.get("hot_scope", "")),
		float(stats.get("hot_scope_usec", 0)) / 1000.0,
	]) + leaf_suffix


func all_interaction_summary_lines() -> Array:
	var lines: Array = []
	for name in _interaction_samples.keys():
		lines.append(interaction_summary_line(String(name)))
	return lines


func summary_line() -> String:
	var hot_scope := ""
	var hot_usec := 0
	for name in _scope_totals.keys():
		var elapsed := int(_scope_totals[name])
		if elapsed > hot_usec:
			hot_usec = elapsed
			hot_scope = String(name)
	return "frame %.2fms max %.2fms hot %s %.2fms ctr:%d" % [
		float(last_frame_usec) / 1000.0,
		float(max_frame_usec) / 1000.0,
		hot_scope,
		float(hot_usec) / 1000.0,
		counters.size(),
	]
