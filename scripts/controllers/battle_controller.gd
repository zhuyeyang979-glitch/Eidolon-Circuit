extends RefCounted
class_name BattleController

var main_ref: Object
var state_store
var dirty_graph
var cache
var profiler
var gpu_geometry_service
var tick_count := 0


func bind(main: Object, store, graph, derived_cache, hot_profiler, geometry_service) -> void:
	main_ref = main
	state_store = store
	dirty_graph = graph
	cache = derived_cache
	profiler = hot_profiler
	gpu_geometry_service = geometry_service


func note_tick() -> void:
	tick_count += 1
	if profiler != null:
		profiler.count("battle.tick")


func summary_line() -> String:
	return "battle ctrl ticks:%d" % tick_count
