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
	var valid_report: Dictionary = service.audit_socket_sizes({
		"socket_attachments": [
			{"socket_id": "torso_port:0", "part_name": "MID ARM", "part_size": "M", "socket_capacity": "M"},
			{"socket_id": "torso_port:1", "part_name": "SMALL GUN", "part_size": 2, "socket_capacity": 3},
		],
	})
	_require(bool(valid_report.get("valid", false)), "Equal or smaller parts should fit sockets: %s" % str(valid_report))
	_require(int(Dictionary(valid_report.get("metrics", {})).get("checked_socket_count", -1)) == 2, "Valid report should count checked sockets.")

	var oversized_report: Dictionary = service.audit_socket_sizes({
		"socket_attachments": [
			{"socket_id": "torso_port:2", "part_name": "SIEGE CANNON", "part_size": "XL", "socket_capacity": "M"},
		],
	})
	_require(not bool(oversized_report.get("valid", true)), "Oversized part should be rejected.")
	_require(_has_code(oversized_report, "socket_part_too_large"), "Oversized part should report socket_part_too_large: %s" % str(oversized_report))
	_require(_has_localized_message(oversized_report), "Oversized socket issue should include Chinese and English messages.")
	var issue := _first_issue(oversized_report)
	_require(String(issue.get("socket_id", "")) == "torso_port:2", "Issue should preserve socket id.")
	_require(int(issue.get("part_size", 0)) == 5 and int(issue.get("socket_capacity", 0)) == 3, "Issue should expose normalized ranks: %s" % str(issue))

	var payload_report: Dictionary = service.audit_socket_sizes({
		"slot_payloads": [
			{"kind": "engine", "socket_id": "engine_slot:0", "socket_capacity": "S", "part": {"name": "HEAVY ENGINE", "slot_volume_tier": "L"}},
		],
	})
	_require(not bool(payload_report.get("valid", true)), "Slot payload part tier should also be audited.")
	_require(_has_code(payload_report, "socket_part_too_large"), "Slot payload size failure should use the same code.")
	_require(int(Dictionary(payload_report.get("metrics", {})).get("oversized_socket_count", 0)) == 1, "Payload report should count one oversized socket.")

	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_SOCKET_SIZE_REJECTION_PROBE ok")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)
