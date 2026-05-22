extends RefCounted
class_name PartCatalogService

var main_ref: Object
var filtered_cache := {}
var hit_count := 0
var miss_count := 0
var invalidation_count := 0


func bind(main: Object) -> void:
	main_ref = main


func preview_cache_key(slot_key: String, part: Dictionary, preview_size: Vector2, theme_revision: int = 0, language_revision: int = 0) -> String:
	var stable := String(part.get("stable_key", part.get("key", part.get("name_en", part.get("name", "")))))
	if stable == "":
		stable = "%s:%s" % [slot_key, str(part.get("index", part.get("part_index", 0)))]
	return "%s|%s|%dx%d|t%d|l%d" % [
		slot_key,
		stable,
		int(preview_size.x),
		int(preview_size.y),
		theme_revision,
		language_revision,
	]


func get_filtered_entries(cache_key: String, compute_callable: Callable) -> Array:
	if filtered_cache.has(cache_key):
		hit_count += 1
		return (filtered_cache[cache_key] as Array).duplicate()
	miss_count += 1
	var value: Array = compute_callable.call() if compute_callable.is_valid() else []
	filtered_cache[cache_key] = value.duplicate()
	return value


func invalidate() -> void:
	filtered_cache.clear()
	invalidation_count += 1


func summary_line() -> String:
	return "catalog svc h/m:%d/%d inv:%d" % [hit_count, miss_count, invalidation_count]
