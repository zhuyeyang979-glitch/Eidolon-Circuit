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
	]
	for path in required_files:
		if not FileAccess.file_exists(path):
			_fail("Missing extraction service %s." % path)
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/main.gd"))
	for symbol in ["ActionProfileRegistry", "DriveSystemService", "UnitBlueprintValidator", "DataRuleService", "LoadingLifecycleService", "UILifecycleService", "action_profile_registry", "drive_system_service", "unit_blueprint_validator", "data_rule_service"]:
		if source.find(symbol) < 0:
			_fail("main.gd does not reference %s." % symbol)
	for delegated in ["LoadingLifecycleService.prepare_task", "LoadingLifecycleService.queue_deferred_idle_tasks", "UILifecycleService.layer_snapshot", "UILifecycleService.trim_dictionary_cache"]:
		if source.find(delegated) < 0:
			_fail("main.gd should delegate extracted glue through %s." % delegated)
	print("MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=%d" % required_files.size())
	quit()
