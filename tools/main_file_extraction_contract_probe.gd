extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var required_files := [
		"res://scripts/services/action_profile_registry.gd",
		"res://scripts/services/drive_system_service.gd",
		"res://scripts/services/unit_blueprint_validator.gd",
		"res://scripts/services/data_rule_service.gd",
		"res://scripts/services/loading_lifecycle_service.gd",
		"res://scripts/services/ui_lifecycle_service.gd",
		"res://scripts/services/unit_stats_service.gd",
		"res://scripts/services/unit_editor_assembly_template_service.gd",
		"res://scripts/services/unit_editor_engine_allocation_service.gd",
	]
	for path in required_files:
		if not FileAccess.file_exists(path):
			_fail("Missing extraction service %s." % path)
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/main.gd"))
	for symbol in ["ActionProfileRegistry", "DriveSystemService", "UnitBlueprintValidator", "DataRuleService", "LoadingLifecycleService", "UILifecycleService", "UnitStatsService", "UnitEditorAssemblyTemplateService", "UnitEditorEngineAllocationService", "action_profile_registry", "drive_system_service", "unit_blueprint_validator", "data_rule_service", "unit_stats_service", "unit_editor_assembly_template_service", "unit_editor_engine_allocation_service"]:
		if source.find(symbol) < 0:
			_fail("main.gd does not reference %s." % symbol)
	for delegated in ["LoadingLifecycleService.prepare_task", "LoadingLifecycleService.queue_deferred_idle_tasks", "UILifecycleService.layer_snapshot", "UILifecycleService.trim_dictionary_cache", "_unit_stats_service().copy_part_logic_stats", "_unit_stats_service().copy_part_combat_stats", "_unit_stats_service().copy_part_payload_stats", "_unit_stats_service().payload_slot_key_for_kind(", "_unit_stats_service().volume_tier_rank(", "_unit_stats_service().volume_rank_from_value(", "_unit_stats_service().part_slot_volume_rank(", "_unit_stats_service().internal_slot_accepts_payload(", "_unit_stats_service().torso_internal_slot_size_ranks(", "_unit_stats_service().best_internal_slot_for_payload(", "_unit_stats_service().apply_torso_payload_direct_stats", "_unit_stats_service().record_torso_payload_summary_entry", "_unit_stats_service().torso_payload_processing_plan", "_unit_stats_service().apply_torso_payload_plan", "_unit_stats_service().apply_ether_payload_stats", "_unit_stats_service().apply_soul_heat_capacity_stats", "_unit_stats_service().apply_soul_bonus_stats", "_unit_stats_service().apply_internal_payload_merge_plan", "_unit_stats_service().apply_torso_payload_summary", "_unit_stats_service().apply_base_motion_envelope", "_unit_stats_service().apply_role_deploy_profile", "_unit_stats_service().apply_manufacturer_discount"]:
		if source.find(delegated) < 0:
			_fail("main.gd should delegate extracted glue through %s." % delegated)
	print("MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=%d" % required_files.size())
	quit()
