extends RefCounted
class_name UnitStatsService

var main_ref: Object
var cache
var hit_count := 0
var miss_count := 0


func bind(main: Object, next_cache) -> void:
	main_ref = main
	cache = next_cache


func stats_key(unit_bp: Dictionary, revision_key: Variant) -> String:
	return "%s:%s:%s" % [
		str(unit_bp.get("unit_name", unit_bp.get("name", ""))),
		str(unit_bp.get("schema_version", unit_bp.get("save_schema", ""))),
		str(revision_key),
	]


func get_cached_stats(ns_name: String, unit_bp: Dictionary, revision_key: Variant, compute_callable: Callable) -> Variant:
	if cache == null:
		miss_count += 1
		return compute_callable.call() if compute_callable.is_valid() else {}
	var key := stats_key(unit_bp, revision_key)
	if cache.has_value(ns_name, key, revision_key):
		hit_count += 1
	else:
		miss_count += 1
	return cache.get_value(ns_name, key, revision_key, compute_callable)


func summary_line() -> String:
	return "stats svc h/m:%d/%d" % [hit_count, miss_count]
