extends SceneTree

const UnitEditorLegalityService := preload("res://scripts/services/unit_editor_legality_service.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _has_code(report: Dictionary, code: String) -> bool:
	return Array(report.get("blocking_codes", [])).has(code)


func _first_issue(report: Dictionary) -> Dictionary:
	var issues: Array = Array(report.get("issues", []))
	if issues.is_empty() or not (issues[0] is Dictionary):
		return {}
	return Dictionary(issues[0])


func _has_localized_message(report: Dictionary) -> bool:
	var issue := _first_issue(report)
	return String(issue.get("message_zh", "")).strip_edges() != "" and String(issue.get("message_en", "")).strip_edges() != ""


func _init() -> void:
	var service := UnitEditorLegalityService.new()
	var mixed_report: Dictionary = service.audit_construct_body_manufacturers({
		"construct_bodies": [
			{
				"body_id": "body-a",
				"parts": [
					{"name": "CORE", "maker": "SYNTAX ELEVEN", "slot_key": "muscle"},
					{"name": "ARM", "maker": "CRUSTA DYNAMICS", "slot_key": "limb_muscle"},
					{"name": "CODE", "maker": "NULL SOFTWARE", "kind": "code", "slot_key": "special"},
				],
			},
		],
	})
	_require(not bool(mixed_report.get("valid", true)), "Mixed hardware manufacturers in one construct body should be rejected.")
	_require(_has_code(mixed_report, "construct_body_mixed_manufacturer"), "Mixed body should report construct_body_mixed_manufacturer: %s" % str(mixed_report))
	_require(_has_localized_message(mixed_report), "Mixed manufacturer issue should include Chinese and English messages.")
	var mixed_issue := _first_issue(mixed_report)
	_require(String(mixed_issue.get("body_id", "")) == "body-a", "Issue should preserve construct body id.")
	_require(Array(mixed_issue.get("manufacturers", [])).has("SYNTAX ELEVEN") and Array(mixed_issue.get("manufacturers", [])).has("CRUSTA DYNAMICS"), "Issue should expose hardware makers: %s" % str(mixed_issue))
	_require(not Array(mixed_issue.get("manufacturers", [])).has("NULL SOFTWARE"), "Software maker should not count as a hardware maker.")

	var split_report: Dictionary = service.audit_construct_body_manufacturers({
		"construct_bodies": [
			{
				"body_id": "body-a",
				"parts": [
					{"name": "CORE", "maker": "SYNTAX ELEVEN", "slot_key": "muscle"},
					{"name": "ENGINE", "maker": "SYNTAX ELEVEN", "slot_key": "engine"},
					{"name": "SOUL", "maker": "NULL SOFTWARE", "kind": "soul", "slot_key": "special"},
				],
			},
			{
				"body_id": "body-b",
				"parts": [
					{"name": "CORE", "maker": "CRUSTA DYNAMICS", "slot_key": "muscle"},
					{"name": "COOLER", "maker": "CRUSTA DYNAMICS", "slot_key": "cooling"},
					{"name": "MODULE", "maker": "BOOTLEG GHOST", "kind": "module", "slot_key": "module"},
				],
			},
		],
	})
	_require(bool(split_report.get("valid", false)), "Separate construct bodies should each be allowed their own hardware maker: %s" % str(split_report))
	_require(int(Dictionary(split_report.get("metrics", {})).get("checked_construct_body_count", -1)) == 2, "Valid report should count checked bodies.")

	var record_report: Dictionary = service.audit_construct_body_manufacturers({
		"construct_body_manufacturer_records": [
			{"body_id": "body-c", "parts": [{"maker": "LONGSIGHT AEGIS", "slot_key": "weapon"}, {"maker": "REDLINE ARMS", "slot_key": "weapon"}]},
		],
	})
	_require(not bool(record_report.get("valid", true)), "Alternate record key should be audited.")
	_require(int(Dictionary(record_report.get("metrics", {})).get("mixed_construct_body_count", 0)) == 1, "Record report should count one mixed body.")

	if failed:
		quit(1)
		return
	print("CONSTRUCT_BODY_MANUFACTURER_REJECTION_PROBE ok")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)
