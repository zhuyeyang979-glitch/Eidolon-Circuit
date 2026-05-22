extends RefCounted
class_name HotPathProfiler

const MAX_HISTORY := 180

var frame_index := 0
var last_frame_usec := 0
var max_frame_usec := 0
var counters := {}
var values := {}
var _scope_stack := []
var _scope_totals := {}
var _scope_counts := {}
var _frame_history := []


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


func count(name: String, amount: int = 1) -> void:
	counters[name] = int(counters.get(name, 0)) + amount


func record_value(name: String, value: Variant) -> void:
	values[name] = value


func scope_stats() -> Dictionary:
	var result := {}
	for name in _scope_totals.keys():
		result[name] = {
			"usec": int(_scope_totals[name]),
			"count": int(_scope_counts.get(name, 0)),
		}
	return result


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
