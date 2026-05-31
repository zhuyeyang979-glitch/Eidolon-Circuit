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


func summary_line() -> String:
	return "teamedit ctrl mark:%d flush:%d" % [mark_count, flush_count]
