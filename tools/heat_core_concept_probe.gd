extends SceneTree

const UnitBuildRuleService := preload("res://scripts/services/unit_build_rule_service.gd")
const UnitEditorAssemblyGuideService := preload("res://scripts/services/unit_editor_assembly_guide_service.gd")
const BattleHudStateService := preload("res://scripts/services/battle_hud_state_service.gd")
const TrainingValidationReportService := preload("res://scripts/services/training_validation_report_service.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _has_entry(entries: Array, code: String) -> bool:
	for raw_entry in entries:
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("code", "")) == code:
			return true
	return false


func _init() -> void:
	var doctrine_script = load("res://scripts/services/heat_doctrine_service.gd")
	if doctrine_script == null:
		_fail("HeatDoctrineService should provide the shared heat vocabulary.")
	else:
		var doctrine = doctrine_script.new()
		for sample in [
			{"context": {"heat_ratio": 0.20}, "stage": "stable"},
			{"context": {"heat_ratio": 0.60}, "stage": "pressure"},
			{"context": {"heat_ratio": 0.82}, "stage": "decision"},
			{"context": {"heat_ratio": 0.82, "cooling_exposed": true}, "stage": "vent"},
			{"context": {"heat_ratio": 1.0, "overheated": true}, "stage": "overheat"},
		]:
			var actual := String(doctrine.rhythm_stage(Dictionary(sample["context"])))
			if actual != String(sample["stage"]):
				_fail("Heat rhythm stage mismatch: expected %s got %s." % [String(sample["stage"]), actual])
		var profile: Dictionary = doctrine.build_profile(1.40)
		if String(profile.get("key", "")) != "redline" or not bool(profile.get("advisory_only", false)):
			_fail("High-output heat profile should be advisory redline: %s" % str(profile))

	var build_audit := UnitBuildRuleService.new().audit({
		"role_key": "hero",
		"metrics": {"heat_peak_ratio": 2.0},
	})
	if bool(build_audit.get("hard_invalid", false)):
		_fail("Heat alone must never make a player design illegal: %s" % str(build_audit))
	var heat_core: Dictionary = Dictionary(build_audit.get("heat_core", {}))
	if String(heat_core.get("key", "")) != "redline" or not bool(heat_core.get("advisory_only", false)):
		_fail("Build audit should expose an advisory heat-core profile: %s" % str(build_audit))

	var guide := UnitEditorAssemblyGuideService.new()
	var cooling_step: Dictionary = guide.step_model("hero", 5, true)
	if String(cooling_step.get("core_concept", "")) != "heat":
		_fail("Beginner cooling step should mark heat as a core concept: %s" % str(cooling_step))
	if String(cooling_step.get("instruction", "")).find("核心") < 0:
		_fail("Beginner cooling guidance should explicitly teach heat as a core concept.")
	var action_step: Dictionary = guide.step_model("hero", 8, true)
	if String(action_step.get("instruction", "")).find("热节奏") < 0:
		_fail("Action binding guidance should tell beginners to review heat rhythm.")

	var hud := BattleHudStateService.new()
	var hud_terms := {
		"heat": "HEAT",
		"heat_stable": "STABLE",
		"heat_pressure": "PRESSURE",
		"heat_decision": "DECIDE",
		"heat_vent": "VENT",
		"heat_overheat": "OVERHEAT",
	}
	var hud_state := {"live": true, "health": 10, "max_health": 10, "uses_heat": true, "heat_ratio": 0.82}
	var hud_text := hud.role_bar_text({"role_key": "hero", "unit": hud_state}, hud_terms)
	if hud_text.find("HEAT 82% DECIDE") < 0:
		_fail("Live HUD should expose the compact heat decision stage: %s" % hud_text)
	hud_state["cooling_exposed"] = true
	if hud.role_bar_text({"role_key": "hero", "unit": hud_state}, hud_terms).find("VENT") < 0:
		_fail("Live HUD should expose committed cooling as VENT.")

	var report_service := TrainingValidationReportService.new()
	var report: Dictionary = report_service.report({
		"units": [{"role": "hero", "stats": {"heat_capacity": 100.0, "normal_heat": 72.0}}],
		"runtime": {"seconds": 8.0, "heat_peak_ratio": 0.82},
	})
	if not _has_entry(Array(report.get("entries", [])), "heat:rhythm"):
		_fail("Training report should always explain the observed heat rhythm: %s" % str(report))
	var report_text := report_service.report_text(report, "zh")
	for phrase in ["核心概念", "进攻", "撤退", "停止行动", "主动散热"]:
		if report_text.find(phrase) < 0:
			_fail("Training guidance should teach heat decision '%s': %s" % [phrase, report_text])

	var readme := FileAccess.get_file_as_string("res://README.md")
	for phrase in ["Heat is the combat-tempo core", "热量是战斗节奏的核心"]:
		if readme.find(phrase) < 0:
			_fail("README should teach the heat core concept: %s" % phrase)
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for phrase in ["预计热节奏", "_editor_heat_core_profile_label", "\"heat_core_label\"", "热量核心：进攻/撤退/停手/G主动散热"]:
		if main_source.find(phrase) < 0:
			_fail("Editor and battle guidance should visibly expose the heat core concept: %s" % phrase)

	if failed:
		quit(1)
		return
	print("HEAT_CORE_CONCEPT_PROBE ok")
	quit(0)
