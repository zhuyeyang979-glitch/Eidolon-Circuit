extends SceneTree

const HeatDoctrineService := preload("res://scripts/services/heat_doctrine_service.gd")
const UnitBuildRuleService := preload("res://scripts/services/unit_build_rule_service.gd")
const TrainingValidationReportService := preload("res://scripts/services/training_validation_report_service.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _array_has(values: Array, needle: String) -> bool:
	for raw_value in values:
		if String(raw_value) == needle:
			return true
	return false


func _init() -> void:
	var doctrine := HeatDoctrineService.new()
	var combat_logic: Dictionary = doctrine.combat_logic()
	if String(combat_logic.get("core_rule", "")) != "burst_windows_not_infinite_chain":
		_fail("Heat doctrine should name burst windows as the core combat logic: %s" % str(combat_logic))
	if not bool(combat_logic.get("advisory_only", false)):
		_fail("Burst-window logic should be advisory and expressive, not a hard legality gate.")
	for hook in ["low_heat_endurance", "redline_overlimit", "cooling_window", "future_heat_traits"]:
		if not _array_has(Array(combat_logic.get("extension_hooks", [])), hook):
			_fail("Combat logic should leave extension hook '%s': %s" % [hook, str(combat_logic)])

	var low_heat_profile: Dictionary = doctrine.build_profile(0.18)
	if String(low_heat_profile.get("playstyle_key", "")) != "low_heat_endurance":
		_fail("Low-heat heroes should be recognized as a deliberate endurance playstyle: %s" % str(low_heat_profile))
	if String(low_heat_profile.get("burst_window_role", "")).find("optional") < 0:
		_fail("Low-heat profile should treat burst windows as optional pressure, not mandatory failure recovery.")

	var redline_profile: Dictionary = doctrine.build_profile(1.72)
	if String(redline_profile.get("playstyle_key", "")) != "redline_overlimit":
		_fail("Redline overlimit should be a supported playstyle hook: %s" % str(redline_profile))
	if String(redline_profile.get("burst_window_role", "")).find("forced") < 0:
		_fail("Redline profile should state that burst windows force exit or vent choices.")

	var audit: Dictionary = UnitBuildRuleService.new().audit({
		"role_key": "hero",
		"metrics": {"heat_peak_ratio": 1.72},
	})
	var heat_core: Dictionary = Dictionary(audit.get("heat_core", {}))
	if bool(audit.get("hard_invalid", false)) or String(heat_core.get("playstyle_key", "")) != "redline_overlimit":
		_fail("Build audit should keep redline overlimit legal but explicit: %s" % str(audit))
	if not _array_has(Array(heat_core.get("extension_hooks", [])), "redline_overlimit"):
		_fail("Build audit heat core should expose future redline hooks: %s" % str(heat_core))

	var report_service := TrainingValidationReportService.new()
	var report: Dictionary = report_service.report({
		"units": [{"role": "hero", "stats": {"heat_capacity": 100.0, "normal_heat": 18.0}}],
		"runtime": {"seconds": 9.0, "heat_peak_ratio": 0.18},
	})
	var zh_text := report_service.report_text(report, "zh")
	for phrase in ["爆发窗口", "不是无限连续攻击", "低热量", "红温超限"]:
		if zh_text.find(phrase) < 0:
			_fail("Training report should teach burst-window logic and alternate heat playstyles: %s" % zh_text)

	var readme := FileAccess.get_file_as_string("res://README.md")
	for phrase in ["burst windows rather than infinite continuous attacks", "爆发窗口，而不是无限连续攻击", "low-heat endurance", "redline overlimit"]:
		if readme.find(phrase) < 0:
			_fail("README should document burst-window heat logic and playstyle hooks: %s" % phrase)

	var plan := FileAccess.get_file_as_string("res://docs/plans/2026-06-15-heat-core-concept.md")
	for phrase in ["Burst Window Logic", "low_heat_endurance", "redline_overlimit", "future_heat_traits"]:
		if plan.find(phrase) < 0:
			_fail("Heat design plan should preserve richer future heat interfaces: %s" % phrase)

	if failed:
		quit(1)
		return
	print("HEAT_BURST_WINDOW_LOGIC_PROBE ok")
	quit(0)
