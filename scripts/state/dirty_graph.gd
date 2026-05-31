extends RefCounted
class_name DirtyGraph

var mark_count := 0
var flush_count := 0
var last_flush_domain := ""
var last_flush_flags := 0
var last_flush_usec := 0
var _domains := {}


func mark(domain: String, dirty_flags: int, reason: String = "") -> void:
	var entry: Dictionary = _domains.get(domain, {
		"flags": 0,
		"reasons": [],
		"mark_count": 0,
		"last_flush_usec": 0,
	})
	entry["flags"] = int(entry.get("flags", 0)) | dirty_flags
	if reason != "":
		var reasons: Array = entry.get("reasons", [])
		if reasons.size() >= 8:
			reasons.pop_front()
		reasons.append(reason)
		entry["reasons"] = reasons
	entry["mark_count"] = int(entry.get("mark_count", 0)) + 1
	_domains[domain] = entry
	mark_count += 1


func flags(domain: String) -> int:
	return int(_domains.get(domain, {}).get("flags", 0))


func reasons(domain: String) -> Array:
	return (_domains.get(domain, {}).get("reasons", []) as Array).duplicate()


func consume(domain: String) -> int:
	var entry: Dictionary = _domains.get(domain, {})
	var current_flags := int(entry.get("flags", 0))
	entry["flags"] = 0
	entry["reasons"] = []
	_domains[domain] = entry
	return current_flags


func begin_flush(domain: String) -> int:
	last_flush_domain = domain
	last_flush_flags = flags(domain)
	return Time.get_ticks_usec()


func finish_flush(domain: String, started_usec: int, consumed_flags: int = -1) -> void:
	var elapsed := Time.get_ticks_usec() - started_usec
	var entry: Dictionary = _domains.get(domain, {})
	entry["last_flush_usec"] = elapsed
	if consumed_flags != -1:
		entry["flags"] = int(entry.get("flags", 0)) & ~consumed_flags
	_domains[domain] = entry
	flush_count += 1
	last_flush_domain = domain
	last_flush_flags = consumed_flags if consumed_flags != -1 else last_flush_flags
	last_flush_usec = elapsed


func pending_domains() -> Array:
	var domains := []
	for domain in _domains.keys():
		if int(_domains[domain].get("flags", 0)) != 0:
			domains.append(domain)
	return domains


func summary_line() -> String:
	var pending := pending_domains()
	return "mark:%d flush:%d last:%s/%d %.2fms pending:%s" % [
		mark_count,
		flush_count,
		last_flush_domain,
		last_flush_flags,
		float(last_flush_usec) / 1000.0,
		",".join(pending),
	]
