extends RefCounted
class_name TeamEditController

var main_ref: Object
var state_store
var dirty_graph
var cache
var profiler
var mark_count := 0
var flush_count := 0

const UNIT_EDITOR_LEGALITY_ACTIONS := {
	"hero_soul_count": {
		"action_key": "fix_role_identity",
		"field_path": "$.blueprint.special",
		"hint_zh": "处理：为英雄保留恰好 1 个英魂软件，再保存。",
		"hint_en": "Action: keep exactly 1 Soul software on the hero, then save again.",
	},
	"puppet_source_code_missing": {
		"action_key": "fix_role_identity",
		"field_path": "$.blueprint.special",
		"hint_zh": "处理：为傀儡安装至少 1 个源代码软件，再保存。",
		"hint_en": "Action: install at least 1 Source Code software on the puppet, then save again.",
	},
	"barrier_ether_missing": {
		"action_key": "fix_role_identity",
		"field_path": "$.blueprint.special",
		"hint_zh": "处理：为结界安装至少 1 个以太软件，再保存。",
		"hint_en": "Action: install at least 1 Ether software on the barrier, then save again.",
	},
	"socket_part_too_large": {
		"action_key": "fit_socket_capacity",
		"field_path": "$.blueprint.slot_payloads",
		"hint_zh": "处理：换用不超过插槽容量的部件，或移到更大的插槽后再保存。",
		"hint_en": "Action: use a part within the socket capacity, or move it to a larger socket before saving.",
	},
	"construct_body_mixed_manufacturer": {
		"action_key": "split_construct_manufacturer",
		"field_path": "$.blueprint.custom_topology",
		"hint_zh": "处理：把同一构件体内的硬件统一为同一厂商，或拆分成不同构件体。",
		"hint_en": "Action: keep hardware in each construct body from one manufacturer, or split the body.",
	},
}


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
	elif _unit_editor_legality_reason_has_action(clean_reason):
		return _unit_editor_legality_feedback(clean_reason, zh)
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


func _unit_editor_legality_reason_has_action(reason: String) -> bool:
	return UNIT_EDITOR_LEGALITY_ACTIONS.has(_reason_code_from_brackets(reason))


func _unit_editor_legality_feedback(reason: String, zh: bool) -> Dictionary:
	var code := _reason_code_from_brackets(reason)
	var spec: Dictionary = Dictionary(UNIT_EDITOR_LEGALITY_ACTIONS.get(code, {}))
	var action_hint := String(spec.get("hint_zh" if zh else "hint_en", ""))
	if action_hint == "":
		action_hint = "处理：先修复提示中的第一个非法条件，再重新保存。" if zh else "Action: fix the first invalid condition named above, then save again."
	var summary := "%s %s" % [reason, action_hint]
	return {
		"reason": reason,
		"action_key": String(spec.get("action_key", "unknown")),
		"action_hint": action_hint,
		"field_path": String(spec.get("field_path", "")),
		"reason_code": code,
		"summary": summary.strip_edges(),
	}


func _reason_code_from_brackets(reason: String) -> String:
	var open_index := reason.rfind("[")
	if open_index < 0:
		return ""
	var close_index := reason.find("]", open_index + 1)
	if close_index <= open_index:
		return ""
	return reason.substr(open_index + 1, close_index - open_index - 1).strip_edges()


func _field_path_after(value: String, marker: String) -> String:
	var index := value.find(marker)
	if index < 0:
		return ""
	return value.substr(index + marker.length()).strip_edges()


func summary_line() -> String:
	return "teamedit ctrl mark:%d flush:%d" % [mark_count, flush_count]
