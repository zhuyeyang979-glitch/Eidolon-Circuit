extends SceneTree

const UnitBuildRuleService := preload("res://scripts/services/unit_build_rule_service.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _has_note(notes: Array, needle: String) -> bool:
	for raw_note in notes:
		if String(raw_note).find(needle) >= 0:
			return true
	return false


func _assert_hard(service: UnitBuildRuleService, label: String, metrics: Dictionary, needle: String) -> void:
	var audit := service.audit({"role_key": "hero", "metrics": metrics})
	if not bool(audit.get("hard_invalid", false)):
		_fail("%s should be hard invalid: %s" % [label, str(audit)])
	var note := service.first_hard_invalid_note(audit)
	if not note.begins_with("INVALID:"):
		_fail("%s hard note should use INVALID prefix: %s" % [label, note])
	if note.find(needle) < 0:
		_fail("%s hard note should mention %s, got %s" % [label, needle, note])


func _assert_warning(service: UnitBuildRuleService, label: String, metrics: Dictionary, needle: String) -> void:
	var audit := service.audit({"role_key": "hero", "metrics": metrics})
	if bool(audit.get("hard_invalid", false)):
		_fail("%s should warn without hard invalid: %s" % [label, str(audit)])
	if not _has_note(Array(audit.get("warnings", [])), needle):
		_fail("%s should warn with %s, got %s" % [label, needle, str(audit)])


func _init() -> void:
	var service := UnitBuildRuleService.new()
	var healthy := service.audit({
		"role_key": "hero",
		"metrics": {
			"idle_mass_ratio": 0.12,
			"weapon_utilization_ratio": 0.86,
			"weapon_mass": 18.0,
			"dominant_role_ratio": 0.62,
			"role_bucket_count": 2,
			"drive_peak_ratio": 0.82,
			"heat_peak_ratio": 0.74,
			"plugin_pressure": 0.58,
		},
	})
	if bool(healthy.get("hard_invalid", true)):
		_fail("Healthy build should not be hard invalid: %s" % str(healthy))
	if not Array(healthy.get("hard_notes", [])).is_empty():
		_fail("Healthy build should have no hard notes: %s" % str(healthy))

	_assert_hard(service, "idle mass", {
		"idle_mass_ratio": 0.60,
		"weapon_utilization_ratio": 0.8,
		"weapon_mass": 12.0,
		"dominant_role_ratio": 0.7,
		"role_bucket_count": 2,
		"drive_peak_ratio": 0.9,
		"heat_peak_ratio": 0.7,
		"plugin_pressure": 0.4,
	}, "idle mass")

	var barrier_structure := service.audit({
		"role_key": "barrier",
		"metrics": {
			"idle_mass_ratio": 0.90,
			"weapon_utilization_ratio": 1.0,
			"weapon_mass": 0.0,
			"dominant_role_ratio": 0.8,
			"role_bucket_count": 2,
			"drive_peak_ratio": 0.0,
			"heat_peak_ratio": 0.0,
			"plugin_pressure": 0.0,
		},
	})
	if bool(barrier_structure.get("hard_invalid", false)):
		_fail("Barrier structure mass should not be treated as idle body material: %s" % str(barrier_structure))

	_assert_hard(service, "weapon utilization", {
		"idle_mass_ratio": 0.1,
		"weapon_utilization_ratio": 0.10,
		"weapon_mass": 16.0,
		"dominant_role_ratio": 0.6,
		"role_bucket_count": 2,
		"drive_peak_ratio": 0.9,
		"heat_peak_ratio": 0.7,
		"plugin_pressure": 0.4,
	}, "weapon utilization")

	_assert_hard(service, "drive peak", {
		"idle_mass_ratio": 0.1,
		"weapon_utilization_ratio": 0.8,
		"weapon_mass": 16.0,
		"dominant_role_ratio": 0.6,
		"role_bucket_count": 2,
		"drive_peak_ratio": 1.50,
		"heat_peak_ratio": 0.7,
		"plugin_pressure": 0.4,
	}, "drive peak")

	_assert_warning(service, "diffuse role", {
		"idle_mass_ratio": 0.12,
		"weapon_utilization_ratio": 0.86,
		"weapon_mass": 18.0,
		"dominant_role_ratio": 0.28,
		"role_bucket_count": 4,
		"drive_peak_ratio": 0.82,
		"heat_peak_ratio": 0.74,
		"plugin_pressure": 0.58,
	}, "role identity")

	_assert_warning(service, "heat peak", {
		"idle_mass_ratio": 0.12,
		"weapon_utilization_ratio": 0.86,
		"weapon_mass": 18.0,
		"dominant_role_ratio": 0.62,
		"role_bucket_count": 2,
		"drive_peak_ratio": 0.82,
		"heat_peak_ratio": 1.70,
		"plugin_pressure": 0.58,
	}, "heat peak")

	_assert_warning(service, "plugin pressure", {
		"idle_mass_ratio": 0.12,
		"weapon_utilization_ratio": 0.86,
		"weapon_mass": 18.0,
		"dominant_role_ratio": 0.62,
		"role_bucket_count": 2,
		"drive_peak_ratio": 0.82,
		"heat_peak_ratio": 0.74,
		"plugin_pressure": 0.92,
	}, "plugin pressure")

	if failed:
		quit(1)
		return
	print("UNIT_BUILD_RULE_SERVICE_PROBE ok")
	quit()
