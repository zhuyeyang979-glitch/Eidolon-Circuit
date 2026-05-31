extends RefCounted
class_name ScoutController

var main_ref: Object
var state_store
var dirty_graph
var cache
var profiler


func bind(main: Object, store, graph, derived_cache, hot_profiler) -> void:
	main_ref = main
	state_store = store
	dirty_graph = graph
	cache = derived_cache
	profiler = hot_profiler


func mark_dirty(reason: String = "scout") -> void:
	if state_store != null:
		state_store.mark_dirty("scout", 1, reason)
	if dirty_graph != null:
		dirty_graph.mark("scout", 1, reason)
