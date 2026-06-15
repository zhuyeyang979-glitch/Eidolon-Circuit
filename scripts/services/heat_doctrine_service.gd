extends RefCounted
class_name HeatDoctrineService

const RHYTHM_STABLE := "stable"
const RHYTHM_PRESSURE := "pressure"
const RHYTHM_DECISION := "decision"
const RHYTHM_VENT := "vent"
const RHYTHM_OVERHEAT := "overheat"

const PRESSURE_RATIO := 0.45
const DECISION_RATIO := 0.75
const OVERHEAT_RATIO := 1.0


func combat_logic() -> Dictionary:
	return {
		"core_rule": "burst_windows_not_infinite_chain",
		"summary": "Heat turns repeated offense into readable burst windows instead of infinite continuous attacks.",
		"advisory_only": true,
		"decision_cycle": ["attack", "disengage", "stop", "active_cooling"],
		"extension_hooks": ["low_heat_endurance", "short_burst_rotation", "pressure_loop", "redline_overlimit", "cooling_window", "future_heat_traits"],
	}


func rhythm_stage(context: Dictionary) -> String:
	var heat_ratio := maxf(0.0, float(context.get("heat_ratio", 0.0)))
	if bool(context.get("overheated", false)) or heat_ratio >= OVERHEAT_RATIO:
		return RHYTHM_OVERHEAT
	if bool(context.get("cooling_exposed", false)) or bool(context.get("manual_cooling", false)) or bool(context.get("active_cooling", false)):
		return RHYTHM_VENT
	if heat_ratio >= DECISION_RATIO:
		return RHYTHM_DECISION
	if heat_ratio >= PRESSURE_RATIO:
		return RHYTHM_PRESSURE
	return RHYTHM_STABLE


func rhythm_label(stage: String, terms: Dictionary = {}) -> String:
	var term_key := "heat_%s" % stage
	var fallbacks := {
		RHYTHM_STABLE: "STABLE",
		RHYTHM_PRESSURE: "PRESSURE",
		RHYTHM_DECISION: "DECIDE",
		RHYTHM_VENT: "VENT",
		RHYTHM_OVERHEAT: "OVERHEAT",
	}
	return String(terms.get(term_key, fallbacks.get(stage, stage.to_upper())))


func build_profile(heat_peak_ratio: float) -> Dictionary:
	var ratio := maxf(0.0, heat_peak_ratio)
	var key := "endurance"
	var label := "ENDURANCE"
	var summary := "Generous heat margin supports sustained action."
	var playstyle_key := "low_heat_endurance"
	var burst_window_role := "optional pressure window; low-heat designs can stay active longer without needing a forced vent."
	if ratio > 1.25:
		key = "redline"
		label = "REDLINE"
		summary = "Repeated high-output actions require explicit retreat or vent windows."
		playstyle_key = "redline_overlimit"
		burst_window_role = "forced exit or vent after each overlimit burst window."
	elif ratio >= 0.90:
		key = "pressure"
		label = "PRESSURE"
		summary = "Planned sequences reach or cross the heat buffer."
		playstyle_key = "pressure_loop"
		burst_window_role = "recurring pressure window; finish the exchange before heat decides for you."
	elif ratio >= 0.55:
		key = "burst"
		label = "BURST"
		summary = "Short attack strings should be followed by natural cooling."
		playstyle_key = "short_burst_rotation"
		burst_window_role = "planned short burst followed by movement, stop time, or cooling."
	var logic := combat_logic()
	return {
		"key": key,
		"label": label,
		"heat_peak_ratio": ratio,
		"summary": summary,
		"playstyle_key": playstyle_key,
		"burst_window_role": burst_window_role,
		"priority": "core",
		"advisory_only": true,
		"combat_logic": String(logic.get("core_rule", "")),
		"decision_cycle": Array(logic.get("decision_cycle", [])).duplicate(),
		"extension_hooks": Array(logic.get("extension_hooks", [])).duplicate(),
	}
