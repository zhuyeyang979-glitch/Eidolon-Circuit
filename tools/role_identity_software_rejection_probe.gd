extends SceneTree

const SERVICE_PATH := "res://scripts/services/unit_editor_legality_service.gd"

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _has_code(report: Dictionary, code: String) -> bool:
	return Array(report.get("blocking_codes", [])).has(code)


func _messages_have_locale(report: Dictionary) -> bool:
	var issues: Array = Array(report.get("issues", []))
	if issues.is_empty():
		return false
	for raw_issue in issues:
		if not (raw_issue is Dictionary):
			continue
		var issue: Dictionary = raw_issue
		if String(issue.get("message_zh", "")).strip_edges() != "" and String(issue.get("message_en", "")).strip_edges() != "":
			return true
	return false


func _catalog() -> Dictionary:
	return {
		"special": [
			{"name": "SOUL A", "kind": "soul"},
			{"name": "SOUL B", "kind": "soul"},
			{"name": "CODE A", "kind": "code"},
			{"name": "SOURCE CODE B", "kind": "source_code"},
			{"name": "ETHER A", "kind": "ether"},
			{"name": "PLAIN SOFTWARE", "kind": "module"},
		],
	}


func _blueprint(payloads: Array) -> Dictionary:
	return {"slot_payloads": payloads}


func _init() -> void:
	_require(FileAccess.file_exists(SERVICE_PATH), "Missing UnitEditorLegalityService script.")
	if failed:
		quit(1)
		return
	var ServiceScript = load(SERVICE_PATH)
	_require(ServiceScript != null, "Cannot load UnitEditorLegalityService script.")
	if failed:
		quit(1)
		return
	var service = ServiceScript.new()

	var catalog := _catalog()
	var hero_valid: Dictionary = service.audit_role_identity("hero", _blueprint([{"kind": "special", "special": 0}]), catalog)
	_require(bool(hero_valid.get("valid", false)), "Hero with exactly one Soul should be valid: %s" % str(hero_valid))
	_require(int(Dictionary(hero_valid.get("metrics", {})).get("soul_count", -1)) == 1, "Hero metrics should count one Soul.")

	var hero_missing: Dictionary = service.audit_role_identity("hero", _blueprint([]), catalog)
	_require(not bool(hero_missing.get("valid", true)), "Hero without Soul should be invalid.")
	_require(_has_code(hero_missing, "hero_soul_count"), "Hero missing Soul should report hero_soul_count: %s" % str(hero_missing))
	_require(_messages_have_locale(hero_missing), "Hero issue should include Chinese and English messages.")

	var hero_duplicate: Dictionary = service.audit_role_identity("hero", _blueprint([{"kind": "special", "special": 0}, {"kind": "special", "special": 1}]), catalog)
	_require(not bool(hero_duplicate.get("valid", true)) and _has_code(hero_duplicate, "hero_soul_count"), "Hero with two Souls should be rejected.")

	var puppet_missing: Dictionary = service.audit_role_identity("puppet", _blueprint([{"kind": "special", "special": 0}]), catalog)
	_require(not bool(puppet_missing.get("valid", true)), "Puppet without Source Code should be invalid.")
	_require(_has_code(puppet_missing, "puppet_source_code_missing"), "Puppet missing Source Code should report puppet_source_code_missing: %s" % str(puppet_missing))
	_require(_messages_have_locale(puppet_missing), "Puppet issue should include Chinese and English messages.")

	var puppet_valid: Dictionary = service.audit_role_identity("puppet", _blueprint([{"kind": "special", "special": 2}, {"kind": "special", "special": 3}]), catalog)
	_require(bool(puppet_valid.get("valid", false)), "Puppet with Source Code payloads should be valid: %s" % str(puppet_valid))
	_require(int(Dictionary(puppet_valid.get("metrics", {})).get("source_code_count", -1)) == 2, "Puppet metrics should count Source Code payloads.")

	var barrier_missing: Dictionary = service.audit_role_identity("barrier", _blueprint([{"kind": "special", "special": 2}]), catalog)
	_require(not bool(barrier_missing.get("valid", true)), "Barrier without Ether should be invalid.")
	_require(_has_code(barrier_missing, "barrier_ether_missing"), "Barrier missing Ether should report barrier_ether_missing: %s" % str(barrier_missing))
	_require(_messages_have_locale(barrier_missing), "Barrier issue should include Chinese and English messages.")

	var barrier_valid: Dictionary = service.audit_role_identity("barrier", _blueprint([{"kind": "special", "special": 4}]), catalog)
	_require(bool(barrier_valid.get("valid", false)), "Barrier with Ether should be valid: %s" % str(barrier_valid))

	var explicit_payload: Dictionary = service.audit_role_identity("puppet", {"identity_payloads": [{"kind": "source_code"}]}, {})
	_require(bool(explicit_payload.get("valid", false)), "Service should also accept explicit identity payload dictionaries.")

	if failed:
		quit(1)
		return
	print("ROLE_IDENTITY_SOFTWARE_REJECTION_PROBE ok")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)
