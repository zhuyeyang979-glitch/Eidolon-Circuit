extends RefCounted
class_name UnitBuildRuleService

const HeatDoctrineService = preload("res://scripts/services/heat_doctrine_service.gd")

const IDLE_MASS_WARN_RATIO := 0.40
const IDLE_MASS_HARD_RATIO := 0.55
const WEAPON_MASS_MIN_FOR_UTILIZATION := 6.0
const WEAPON_UTILIZATION_WARN_RATIO := 0.30
const WEAPON_UTILIZATION_HARD_RATIO := 0.15
const DOMINANT_ROLE_WARN_RATIO := 0.35
const DRIVE_PEAK_WARN_RATIO := 1.0
const DRIVE_PEAK_HARD_RATIO := 1.35
const HEAT_PEAK_CAUTION_RATIO := 0.75
const HEAT_PEAK_WARN_RATIO := 1.00
const PLUGIN_PRESSURE_WARN_RATIO := 0.85

var heat_doctrine = HeatDoctrineService.new()


func audit(context: Dictionary) -> Dictionary:
	var metrics := _metrics_from_context(context)
	var hard_notes: Array = []
	var warnings: Array = []
	var score_notes: Array = []
	var role_key := String(context.get("role_key", ""))
	var applicability: Dictionary = context.get("applicability", {})
	var mobile_body_default := role_key != "barrier"
	var idle_mass_applicable := bool(applicability.get("idle_mass", mobile_body_default))
	var weapon_utilization_applicable := bool(applicability.get("weapon_utilization", mobile_body_default))
	var drive_peak_applicable := bool(applicability.get("drive_peak", mobile_body_default))
	var heat_peak_applicable := bool(applicability.get("heat_peak", mobile_body_default))
	var plugin_pressure_applicable := bool(applicability.get("plugin_pressure", mobile_body_default))

	var idle_mass_ratio := _metric(metrics, "idle_mass_ratio", 0.0)
	if idle_mass_applicable and idle_mass_ratio > IDLE_MASS_HARD_RATIO:
		hard_notes.append("INVALID: idle mass %.0f%% exceeds %.0f%%; connect or remove non-functional material." % [idle_mass_ratio * 100.0, IDLE_MASS_HARD_RATIO * 100.0])
	elif idle_mass_applicable and idle_mass_ratio > IDLE_MASS_WARN_RATIO:
		warnings.append("WARN: idle mass %.0f%% is high; unused structure will reduce build efficiency." % [idle_mass_ratio * 100.0])

	var weapon_mass := _metric(metrics, "weapon_mass", 0.0)
	var weapon_utilization_ratio := _metric(metrics, "weapon_utilization_ratio", 1.0)
	if weapon_utilization_applicable and weapon_mass >= WEAPON_MASS_MIN_FOR_UTILIZATION:
		if weapon_utilization_ratio < WEAPON_UTILIZATION_HARD_RATIO:
			hard_notes.append("INVALID: weapon utilization %.0f%% below %.0f%%; bind weapons to action modules or remove unused weapons." % [weapon_utilization_ratio * 100.0, WEAPON_UTILIZATION_HARD_RATIO * 100.0])
		elif weapon_utilization_ratio < WEAPON_UTILIZATION_WARN_RATIO:
			warnings.append("WARN: weapon utilization %.0f%% is low; most weapon mass is not part of a legal action chain." % [weapon_utilization_ratio * 100.0])

	var role_bucket_count := int(metrics.get("role_bucket_count", 0))
	var dominant_role_ratio := _metric(metrics, "dominant_role_ratio", 1.0)
	if role_bucket_count >= 2 and dominant_role_ratio < DOMINANT_ROLE_WARN_RATIO:
		warnings.append("WARN: role identity %.0f%% is diffuse; choose a clearer primary combat function or accept efficiency loss." % [dominant_role_ratio * 100.0])

	var drive_peak_ratio := _metric(metrics, "drive_peak_ratio", 0.0)
	if drive_peak_applicable and drive_peak_ratio > DRIVE_PEAK_HARD_RATIO:
		hard_notes.append("INVALID: drive peak %.0f%% exceeds %.0f%% engine safety limit." % [drive_peak_ratio * 100.0, DRIVE_PEAK_HARD_RATIO * 100.0])
	elif drive_peak_applicable and drive_peak_ratio > DRIVE_PEAK_WARN_RATIO:
		warnings.append("WARN: drive peak %.0f%% exceeds available engine output; attacks or boost will suffer." % [drive_peak_ratio * 100.0])

	var heat_peak_ratio := _metric(metrics, "heat_peak_ratio", 0.0)
	var heat_core: Dictionary = heat_doctrine.build_profile(heat_peak_ratio)
	heat_core["applicable"] = heat_peak_applicable
	if heat_peak_applicable and heat_peak_ratio >= HEAT_PEAK_WARN_RATIO:
		warnings.append("WARN: heat peak %.0f%% creates a %s heat core; plan a burst window, then attack, disengage, stop, or active-cool." % [heat_peak_ratio * 100.0, String(heat_core.get("label", ""))])
	elif heat_peak_applicable and heat_peak_ratio >= HEAT_PEAK_CAUTION_RATIO:
		score_notes.append("HEAT CORE: %s at %.0f%%; choose the next burst window deliberately." % [String(heat_core.get("label", "")), heat_peak_ratio * 100.0])
	elif heat_peak_applicable:
		score_notes.append("HEAT CORE: %s at %.0f%%; heat defines the expected combat rhythm without forcing a fixed style." % [String(heat_core.get("label", "")), heat_peak_ratio * 100.0])

	var plugin_pressure := _metric(metrics, "plugin_pressure", 0.0)
	if plugin_pressure_applicable and plugin_pressure > PLUGIN_PRESSURE_WARN_RATIO:
		warnings.append("WARN: plugin pressure %.0f%% is crowded; existing slot compatibility still owns hard rejection." % [plugin_pressure * 100.0])

	return {
		"hard_invalid": not hard_notes.is_empty(),
		"hard_notes": hard_notes,
		"warnings": warnings,
		"score_notes": score_notes,
		"metrics": metrics,
		"heat_core": heat_core,
	}


func first_hard_invalid_note(audit_result: Dictionary) -> String:
	var hard_notes: Array = Array(audit_result.get("hard_notes", []))
	if hard_notes.is_empty():
		return ""
	return String(hard_notes[0])


func _metrics_from_context(context: Dictionary) -> Dictionary:
	var metrics := {}
	if context.get("metrics", {}) is Dictionary:
		metrics = Dictionary(context.get("metrics", {})).duplicate(true)
	for key in [
		"idle_mass_ratio",
		"weapon_utilization_ratio",
		"weapon_mass",
		"dominant_role_ratio",
		"role_bucket_count",
		"drive_peak_ratio",
		"heat_peak_ratio",
		"plugin_pressure",
	]:
		if context.has(key):
			metrics[key] = context[key]
	return metrics


func _metric(metrics: Dictionary, key: String, fallback: float) -> float:
	return float(metrics.get(key, fallback))
