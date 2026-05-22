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
