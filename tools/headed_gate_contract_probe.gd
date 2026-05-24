extends SceneTree

const GATE_PATH := "res://tools/run_headed_gate.ps1"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _require(text: String, token: String) -> void:
	if text.find(token) < 0:
		_fail("Headed gate script missing token: %s" % token)


func _init() -> void:
	var path := ProjectSettings.globalize_path(GATE_PATH)
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		_fail("Missing headed gate script.")
	for group in ["navigation_menu", "unit_edit", "loading_first_interaction"]:
		_require(text, group)
	for probe in [
		"navigation_router_single_source_probe",
		"navigation_service_contract_probe",
		"main_menu_navigation_probe",
		"options_menu_unification_probe",
		"page_options_router_back_probe",
		"menu_view_controller_contract_probe",
		"menu_view_signal_contract_probe",
		"main_menu_table_actions_probe",
		"page_options_table_router_probe",
		"battle_runtime_options_table_probe",
		"menu_language_table_probe",
		"ui_layout_tokens_contract_probe",
		"layout_tokens_responsive_contract_probe",
		"menu_layout_regression_probe",
		"settings_scout_tokenized_layout_probe",
		"headed_gate_manifest_alignment_probe",
		"teamedit_probe",
		"ui_layout_probe",
		"text_overflow_probe",
		"unit_editor_fullscreen_layout_probe",
		"unit_editor_no_power_topbar_probe",
		"unit_editor_power_dock_moved_up_probe",
		"unit_editor_torso_detail_button_probe",
		"power_allocation_detail_open_close_probe",
		"power_allocation_panel_close_probe",
		"power_allocation_enter_confirms_value_probe",
		"unit_editor_training_illegal_feedback_probe",
		"loading_task_contract_probe",
		"preload_tasks_typed_probe",
		"startup_loading_stage_probe",
		"page_loading_transition_probe",
		"loading_navigation_contract_probe",
		"startup_deep_preload_probe",
		"teamedit_page_deep_preload_probe",
		"post_loading_first_interaction_miss_probe",
		"post_loading_real_interaction_miss_probe",
	]:
		_require(text, probe)
	if text.find("-Headed") < 0:
		_fail("Headed gate must force -Headed low-level runs.")
	if text.find("-Headless") >= 0:
		_fail("Headed gate must not invoke -Headless.")
	if text.find("-CheckOnly") < 0:
		_fail("Headed gate should include headed check-only.")
	print("HEADED_GATE_CONTRACT_PROBE ok")
	quit(0)
