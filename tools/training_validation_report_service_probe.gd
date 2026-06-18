extends SceneTree

const TrainingValidationReportService := preload("res://scripts/services/training_validation_report_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _has_entry(entries: Array, kind: String, code_prefix: String = "") -> bool:
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		if String(entry.get("kind", "")) != kind:
			continue
		if code_prefix == "" or String(entry.get("code", "")).begins_with(code_prefix):
			return true
	return false


func _assert_advisory_shape(report: Dictionary) -> void:
	if bool(report.get("blocking", true)):
		_fail("Training validation report must never block player designs.")
	if not bool(report.get("advisory_only", false)):
		_fail("Training validation report should explicitly mark itself advisory-only.")
	for forbidden_key in ["strength_score", "power_score", "rating_total", "fixed_score"]:
		if report.has(forbidden_key):
			_fail("Training validation report should not expose fixed strength score key: %s" % forbidden_key)
	var entries: Array = Array(report.get("entries", []))
	if entries.is_empty():
		_fail("Training validation report should include advisory entries.")
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			_fail("Training validation entries must be dictionaries.")
		var entry: Dictionary = raw_entry
		if not bool(entry.get("advisory_only", false)):
			_fail("Every training validation entry must be advisory-only: %s" % str(entry))
		if String(entry.get("kind", "")) == "INVALID":
			_fail("Training validation entries must not use hard INVALID kind: %s" % str(entry))


func _init() -> void:
	var service := TrainingValidationReportService.new()
	var report := service.report({
		"intent_key": "ranged_pressure",
		"units": [{
			"role": "hero",
			"name": "Needle Kite",
			"stats": {
				"projectile_range": 3.6,
				"normal_range": 3.2,
				"normal_damage": 9,
				"armor_damage": 4,
				"active_damage": 0,
				"speed": 0.62,
				"turn_speed": 0.48,
				"boost_speed": 0.0,
				"heat_capacity": 40.0,
				"normal_heat": 54.0,
				"active_heat": 20.0,
				"cooling": 1.0,
				"ammo_capacity": {"bullet": 3, "laser": 0, "chemical": 0, "explosive": 0, "web": 0},
			},
		}],
		"runtime": {
			"seconds": 10.0,
			"shots_fired": 12,
			"hits": 4,
			"damage_dealt": 61.0,
			"heat_peak_ratio": 1.82,
			"overheat_count": 1,
			"ammo_spent": 9,
			"ammo_remaining": 0,
			"boost_count": 0,
		},
	})
	_assert_advisory_shape(report)
	var entries: Array = Array(report.get("entries", []))
	if not _has_entry(entries, "OBSERVE", "intent:"):
		_fail("Report should observe the selected or inferred combat intent: %s" % str(entries))
	if not _has_entry(entries, "RISK", "heat:"):
		_fail("Report should flag heat risk from runtime/static heat facts: %s" % str(entries))
	if not _has_entry(entries, "RISK", "ammo:"):
		_fail("Report should flag ammo endurance risk: %s" % str(entries))
	if not _has_entry(entries, "RISK", "accuracy:"):
		_fail("Report should flag low hit stability from runtime miss data: %s" % str(entries))
	if not _has_entry(entries, "COUNTER", "counter:"):
		_fail("Report should describe at least one counter-pressure style: %s" % str(entries))
	if not _has_entry(entries, "SUGGEST", "suggest:"):
		_fail("Report should provide conditional suggestions: %s" % str(entries))
	var zh_text := service.report_text(report, "zh")
	var en_text := service.report_text(report, "en")
	if zh_text.find("训练验证报告") < 0 or zh_text.find("建议") < 0:
		_fail("Chinese report text should expose advisory report and suggestions: %s" % zh_text)
	if en_text.find("TRAINING VALIDATION") < 0 or en_text.find("SUGGEST") < 0:
		_fail("English report text should expose advisory report and suggestions: %s" % en_text)
	print("TRAINING_VALIDATION_REPORT_SERVICE_PROBE ok entries=%d" % entries.size())
	quit(0)
