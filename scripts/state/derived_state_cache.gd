extends RefCounted
class_name DerivedStateCache

var hit_count := 0
var miss_count := 0
var put_count := 0
var invalidation_count := 0
var _namespaces := {}


func _entry_key(key: Variant, revision_key: Variant) -> String:
	return "%s::%s" % [str(key), str(revision_key)]


func has_value(ns_name: String, key: Variant, revision_key: Variant) -> bool:
	var ns: Dictionary = _namespaces.get(ns_name, {})
	return ns.has(_entry_key(key, revision_key))


func get_value(ns_name: String, key: Variant, revision_key: Variant, compute_callable: Variant = null) -> Variant:
	var ns: Dictionary = _namespaces.get(ns_name, {})
	var cache_key := _entry_key(key, revision_key)
	if ns.has(cache_key):
		hit_count += 1
		return ns[cache_key]
	miss_count += 1
	if compute_callable is Callable and compute_callable.is_valid():
		var value: Variant = compute_callable.call()
		put_value(ns_name, key, revision_key, value)
		return value
	return null


func put_value(ns_name: String, key: Variant, revision_key: Variant, value: Variant) -> void:
	var ns: Dictionary = _namespaces.get(ns_name, {})
	ns[_entry_key(key, revision_key)] = value
	_namespaces[ns_name] = ns
	put_count += 1


func invalidate_namespace(ns_name: String) -> void:
	if _namespaces.has(ns_name):
		_namespaces.erase(ns_name)
		invalidation_count += 1


func invalidate_matching(ns_name: String, prefix: String) -> void:
	var ns: Dictionary = _namespaces.get(ns_name, {})
	var removed := false
	for key in ns.keys():
		if String(key).begins_with(prefix):
			ns.erase(key)
			removed = true
	if removed:
		_namespaces[ns_name] = ns
		invalidation_count += 1


func clear() -> void:
	_namespaces.clear()
	invalidation_count += 1


func summary_line() -> String:
	return "cache h/m:%d/%d put:%d inv:%d ns:%d" % [
		hit_count,
		miss_count,
		put_count,
		invalidation_count,
		_namespaces.size(),
	]
