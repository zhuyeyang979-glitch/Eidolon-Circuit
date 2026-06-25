extends RefCounted
class_name BattleController

const StarSoulBPServiceScript := preload("res://scripts/services/star_soul_bp_service.gd")
const StarSoulRuntimeQueueServiceScript := preload("res://scripts/services/star_soul_runtime_queue_service.gd")

var main_ref: Object
var state_store
var dirty_graph
var cache
var profiler
var gpu_geometry_service
var tick_count := 0
var star_soul_runtime_state := {}
var star_soul_catalog_by_id := {}
var star_soul_runtime_service = StarSoulRuntimeQueueServiceScript.new()


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


func start_star_soul_runtime(draft_payload: Dictionary, catalog_by_id: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	star_soul_catalog_by_id = _star_soul_catalog(catalog_by_id)
	star_soul_runtime_state = star_soul_runtime_service.initial_state(draft_payload, star_soul_catalog_by_id, options)
	return star_soul_runtime_snapshot()


func tick_star_soul_runtime(delta: float) -> Dictionary:
	if star_soul_runtime_state.is_empty():
		return {"reason": "not_started", "changed": false, "state": {}}
	var intent: Dictionary = star_soul_runtime_service.tick(star_soul_runtime_state, delta)
	star_soul_runtime_state = Dictionary(intent.get("state", {})).duplicate(true)
	return intent


func commit_star_soul_spawn(runtime_id: String = "") -> Dictionary:
	if star_soul_runtime_state.is_empty():
		return {"reason": "not_started", "changed": false, "state": {}}
	var intent: Dictionary = star_soul_runtime_service.spawn_committed(star_soul_runtime_state, runtime_id)
	star_soul_runtime_state = Dictionary(intent.get("state", {})).duplicate(true)
	return intent


func exit_active_star_soul(exit_reason: String, runtime_id: String = "", options: Dictionary = {}) -> Dictionary:
	if star_soul_runtime_state.is_empty():
		return {"reason": "not_started", "changed": false, "state": {}}
	var intent: Dictionary = star_soul_runtime_service.active_exit(star_soul_runtime_state, exit_reason, runtime_id, options)
	star_soul_runtime_state = Dictionary(intent.get("state", {})).duplicate(true)
	return intent


func star_soul_runtime_snapshot() -> Dictionary:
	return star_soul_runtime_state.duplicate(true)


func star_soul_hud_snapshot() -> Dictionary:
	return star_soul_runtime_snapshot()


func clear_star_soul_runtime() -> void:
	star_soul_runtime_state = {}


func _star_soul_catalog(catalog_by_id: Dictionary) -> Dictionary:
	if not catalog_by_id.is_empty():
		var result := {}
		for key in catalog_by_id.keys():
			var entry = catalog_by_id[key]
			if entry is Dictionary:
				result[str(key)] = Dictionary(entry).duplicate(true)
		return result
	var bp_service = StarSoulBPServiceScript.new()
	return bp_service.catalog_by_id()
