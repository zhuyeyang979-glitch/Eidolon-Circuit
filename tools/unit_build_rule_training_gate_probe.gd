extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const UnitBuildRuleService := preload("res://scripts/services/unit_build_rule_service.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if not main.has_method("_unit_build_rule_audit"):
		_fail("Main scene should expose _unit_build_rule_audit.")
		quit(1)
		return
	var blank_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var blank_stats := main._compute_unit_stats(1, "hero", -1, blank_bp)
	var audit: Dictionary = main._unit_build_rule_audit("hero", blank_bp, blank_stats)
	if not audit.has("metrics") or not audit.has("hard_invalid"):
		_fail("Build rule audit should return structured metrics and hard_invalid flag: %s" % str(audit))
	var synthetic_stats := {
		"mass": 100.0,
		"idle_mass": 60.0,
		"weapon_mass": 20.0,
		"action_bound_weapon_mass": 1.0,
		"drive_demand_total": 150.0,
		"drive_output_total": 100.0,
		"normal_heat": 2.0,
		"armor_heat": 3.0,
		"active_heat": 4.0,
		"boost_heat": 0.0,
		"heat_capacity": 40.0,
	}
	var synthetic_audit: Dictionary = main._unit_build_rule_audit("hero", {}, synthetic_stats)
	var hard_note := UnitBuildRuleService.new().first_hard_invalid_note(synthetic_audit)
	if hard_note.find("idle mass") < 0:
		_fail("Synthetic idle-mass build should hard-block through main audit, got %s" % str(synthetic_audit))
	var barrier_audit: Dictionary = main._unit_build_rule_audit("barrier", {}, synthetic_stats)
	if bool(barrier_audit.get("hard_invalid", false)):
		_fail("Barrier structure should be exempt from mobile-body idle mass rules: %s" % str(barrier_audit))
	var blank_note := main._training_blueprint_illegal_note(1, "hero", blank_bp)
	if blank_note.find("blank topology") < 0:
		_fail("Existing blank topology error should stay ahead of build audit, got %s" % blank_note)
	if failed:
		quit(1)
		return
	print("UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok hard=%s blank=%s" % [hard_note, blank_note])
	quit()
