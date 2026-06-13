extends RefCounted
class_name TeamEditController

var main_ref: Object
var state_store
var dirty_graph
var cache
var profiler
var mark_count := 0
var flush_count := 0


func bind(main: Object, store, graph, derived_cache, hot_profiler) -> void:
	main_ref = main
	state_store = store
	dirty_graph = graph
	cache = derived_cache
	profiler = hot_profiler


func mark_dirty(flags: int, reason: String = "teamedit") -> void:
	mark_count += 1
	if state_store != null:
		state_store.mark_dirty("editor", flags, reason)
	if dirty_graph != null:
		dirty_graph.mark("editor", flags, reason)
	if profiler != null:
		profiler.count("teamedit.mark_dirty")


func note_flush(flags: int, elapsed_usec: int) -> void:
	flush_count += 1
	if profiler != null:
		profiler.record_value("teamedit.last_flush_usec", elapsed_usec)
	if dirty_graph != null:
		dirty_graph.finish_flush("editor", Time.get_ticks_usec() - elapsed_usec, flags)


func save_blocking_feedback(reason: String, zh: bool = false) -> Dictionary:
	var clean_reason := reason.strip_edges()
	var reason_was_blank := clean_reason == ""
	if clean_reason == "":
		clean_reason = "unknown validation failure"
	var lower_reason := clean_reason.to_lower()
	var action_key := "unknown"
	var field_path := ""
	var action_hint := ""
	if reason_was_blank:
		action_key = "unknown"
		action_hint = "处理：先修复提示中的第一个非法条件，再重新保存。" if zh else "Action: fix the first invalid condition named above, then save again."
	elif lower_reason.contains("legacy drive/pointer field"):
		action_key = "remove_legacy_field"
		field_path = _field_path_after(clean_reason, " at ")
		var target := field_path if field_path != "" else clean_reason
		action_hint = "处理：删除或重建旧字段 %s，再保存。" % target if zh else "Action: remove or rebuild the legacy field %s, then save again." % target
	elif lower_reason.contains("legacy nonphysical combat field"):
		action_key = "remove_legacy_combat_field"
		field_path = _field_path_after(clean_reason, " at ")
		var combat_target := field_path if field_path != "" else clean_reason
		action_hint = "处理：删除旧战斗字段 %s，或用当前编辑器重新生成该单位。" % combat_target if zh else "Action: remove the legacy combat field %s, or rebuild this unit in the current editor." % combat_target
	elif lower_reason.contains("missing blueprint"):
		action_key = "restore_blueprint"
		action_hint = "处理：载入包含蓝图的单位文件，或回到单位编辑重新保存。" if zh else "Action: load a unit file with a blueprint, or rebuild and save it from Unit Edit."
	elif lower_reason.contains("custom topology") or lower_reason.contains("topology"):
		action_key = "rebuild_topology"
		action_hint = "处理：在自由画布放置当前拓扑构件并重新保存。" if zh else "Action: rebuild the current free-canvas topology before saving."
	elif lower_reason.contains("cannot write"):
		action_key = "check_write_access"
		action_hint = "处理：检查单位库文件夹写入权限，或换一个另存路径。" if zh else "Action: check write access to the unit library folder, or use Save As."
	elif lower_reason.contains("read back") or lower_reason.contains("validation"):
		action_key = "retry_save_as"
		action_hint = "处理：保持当前画布，使用另存为重试；若仍失败，检查提示中的第一个非法字段。" if zh else "Action: keep this canvas open and retry with Save As; if it still fails, fix the first invalid field named above."
	else:
		action_hint = "处理：先修复提示中的第一个非法条件，再重新保存。" if zh else "Action: fix the first invalid condition named above, then save again."
	var summary := "%s %s" % [clean_reason, action_hint]
	return {
		"reason": clean_reason,
		"action_key": action_key,
		"action_hint": action_hint,
		"field_path": field_path,
		"summary": summary.strip_edges(),
	}


func _field_path_after(value: String, marker: String) -> String:
	var index := value.find(marker)
	if index < 0:
		return ""
	return value.substr(index + marker.length()).strip_edges()


func summary_line() -> String:
	return "teamedit ctrl mark:%d flush:%d" % [mark_count, flush_count]
