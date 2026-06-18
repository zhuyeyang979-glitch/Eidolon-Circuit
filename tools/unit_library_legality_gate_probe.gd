extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const UnitBuildRuleService := preload("res://scripts/services/unit_build_rule_service.gd")
const LegalStarterBlueprintFixture := preload("res://tools/fixtures/legal_starter_blueprint_fixture.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor(true)

	var invalid_path := "%s/legality_gate_invalid_%d.json" % [MainScene.SAVED_UNITS_DIR, int(Time.get_ticks_msec())]
	var invalid_bp: Dictionary = main._editor_current_blueprint()
	invalid_bp["custom_topology"] = main._default_free_canvas_topology("hero")
	invalid_bp["blank_canvas"] = false
	invalid_bp["unit_name"] = "Legality Gate Invalid"
	var hard_note := main._training_blueprint_illegal_note(1, "hero", invalid_bp)
	if hard_note == "":
		_fail("Probe fixture should be canonical but construction-invalid.")
		return
	var invalid_result := main._save_editor_current_unit_to_library_named("Legality Gate Invalid", invalid_path, true)
	if invalid_result != "":
		if FileAccess.file_exists(invalid_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(invalid_path))
		_fail("Construction-invalid unit should be rejected before write, got %s with %s" % [invalid_result, hard_note])
		return
	if FileAccess.file_exists(invalid_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(invalid_path))
		_fail("Construction-invalid unit created a library file.")
		return

	var warning_audit := UnitBuildRuleService.new().audit({
		"role_key": "hero",
		"metrics": {
			"idle_mass_ratio": 0.45,
			"weapon_utilization_ratio": 0.8,
			"weapon_mass": 12.0,
			"dominant_role_ratio": 0.6,
			"role_bucket_count": 2,
			"drive_peak_ratio": 0.9,
			"heat_peak_ratio": 0.8,
			"plugin_pressure": 0.5,
		},
	})
	if bool(warning_audit.get("hard_invalid", true)) or Array(warning_audit.get("warnings", [])).is_empty():
		_fail("Warning-only audit should remain save-eligible: %s" % str(warning_audit))
		return

	var legal_bp := LegalStarterBlueprintFixture.build(main, "Library Legal Starter")
	if legal_bp.is_empty():
		_fail("Could not build legal starter fixture.")
		return
	main.editor_working_blueprint = legal_bp
	main.editor_working_role_key = "hero"
	main.editor_canvas_mode = "blank"
	var legal_path := "%s/legality_gate_legal_%d.json" % [MainScene.SAVED_UNITS_DIR, int(Time.get_ticks_msec())]
	var legal_result := main._save_editor_current_unit_to_library_named("Legality Gate Legal", legal_path, true)
	if legal_result != legal_path or not FileAccess.file_exists(legal_path):
		_fail("Legal unit should save successfully, got %s" % legal_result)
		return
	var readback := main._unit_library_entry_from_file(legal_path)
	if readback.is_empty() or main._saved_unit_entry_illegal_note(readback) != "":
		_fail("Saved legal unit should read back as deployable: %s" % str(readback))
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(legal_path))
	print("UNIT_LIBRARY_LEGALITY_GATE_PROBE ok rejected=%s saved=%s" % [hard_note, legal_path])
	quit(0)
