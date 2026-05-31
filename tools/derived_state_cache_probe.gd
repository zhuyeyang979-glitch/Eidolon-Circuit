extends SceneTree

const DerivedStateCacheScript = preload("res://scripts/state/derived_state_cache.gd")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var cache = DerivedStateCacheScript.new()
	cache.put_value("stats", "unit-a", 1, {"hp": 10})
	var value: Variant = cache.get_value("stats", "unit-a", 1)
	if typeof(value) != TYPE_DICTIONARY or int(value.get("hp", 0)) != 10:
		_fail("DerivedStateCache get_value failed.")
		return
	if cache.hit_count != 1:
		_fail("DerivedStateCache did not count cache hit.")
		return
	var computed: Variant = cache.get_value("stats", "unit-b", 1, func(): return {"hp": 12})
	if typeof(computed) != TYPE_DICTIONARY or int(computed.get("hp", 0)) != 12:
		_fail("DerivedStateCache compute callback failed.")
		return
	if cache.miss_count != 1:
		_fail("DerivedStateCache did not count miss.")
		return
	cache.invalidate_namespace("stats")
	if cache.has_value("stats", "unit-a", 1):
		_fail("DerivedStateCache namespace invalidation failed.")
		return
	print("DERIVED_STATE_CACHE_PROBE ok")
	quit(0)
