extends SceneTree

const ARCH_DOC := "res://docs/architecture_boundaries.md"
const MAIN_PATH := "res://scripts/main.gd"
const MANIFEST_PATH := "res://tools/probe_manifest.json"
const INLINE_GUARD_PATH := "res://tools/main_inline_class_guard_probe.gd"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _require_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		_fail("Missing required architecture boundary file: %s" % path)
		return ""
	var text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))
	if text.strip_edges() == "":
		_fail("Required architecture boundary file is empty: %s" % path)
	return text


func _require_tokens(text: String, tokens: Array, label: String) -> void:
	for raw_token in tokens:
		var token := String(raw_token)
		if text.find(token) < 0:
			_fail("%s missing required token: %s" % [label, token])


func _init() -> void:
	var arch_doc := _require_file(ARCH_DOC)
	_require_tokens(arch_doc, [
		"AppRoot",
		"Modes",
		"Domain",
		"Battle Runtime",
		"BattleState",
		"BattleFixedTickRunner",
		"Presentation",
		"Persistence",
		"Probe Policy",
		"tools/app_root_boundary_probe.gd",
		"tools/app_mode_host_contract_probe.gd",
		"tools/battle_state_contract_probe.gd",
		"tools/battle_mode_contract_probe.gd",
		"tools/menu_mode_contract_probe.gd",
		"tools/team_edit_mode_contract_probe.gd",
		"tools/saved_units_mode_contract_probe.gd",
		"tools/settings_mode_contract_probe.gd",
		"tools/training_mode_contract_probe.gd",
	], "architecture boundary doc")

	var main_source := _require_file(MAIN_PATH)
	_require_tokens(main_source, [
		"extends Node2D",
		"const AppModeHost = preload(\"res://scripts/app/app_mode_host.gd\")",
		"var app_mode_host: AppModeHost",
		"app_mode_host = AppModeHost.new()",
		"func _app_mode_key_for_page",
		"func _commit_app_mode_for_page",
		"_commit_app_mode_for_page(target_state, nav_reason, payload)",
		"const BattleMode = preload(\"res://scripts/modes/battle_mode.gd\")",
		"var battle_mode_owner: BattleMode",
		"battle_mode_owner.bind(self, battle_controller, battle_runtime_lifecycle_service)",
		"func _commit_battle_mode_enter",
		"func _commit_battle_mode_exit",
		"func _battle_mode_show_intent",
		"battle_mode_owner.show_intent",
		"func _battle_mode_cleanup_intent",
		"battle_mode_owner.cleanup_intent",
		"const MenuMode = preload(\"res://scripts/modes/menu_mode.gd\")",
		"var menu_mode_owner: MenuMode",
		"menu_mode_owner.bind(self, menu_controller, menu_view)",
		"func _commit_menu_mode_enter",
		"func _commit_menu_mode_exit",
		"func _menu_mode_show_intent",
		"menu_mode_owner.show_intent",
		"const TeamEditMode = preload(\"res://scripts/modes/team_edit_mode.gd\")",
		"var team_edit_mode_owner: TeamEditMode",
		"team_edit_mode_owner.bind(self, team_edit_controller)",
		"func _commit_team_edit_mode_enter",
		"func _commit_team_edit_mode_exit",
		"func _team_edit_mode_show_intent",
		"team_edit_mode_owner.show_intent",
		"const SavedUnitsMode = preload(\"res://scripts/modes/saved_units_mode.gd\")",
		"var saved_units_mode_owner: SavedUnitsMode",
		"saved_units_mode_owner.bind(self, saved_units_controller)",
		"func _commit_saved_units_mode_enter",
		"func _commit_saved_units_mode_exit",
		"func _saved_units_mode_show_intent",
		"saved_units_mode_owner.show_intent",
		"const SettingsMode = preload(\"res://scripts/modes/settings_mode.gd\")",
		"var settings_mode_owner: SettingsMode",
		"settings_mode_owner.bind(self, settings_controller)",
		"func _commit_settings_mode_enter",
		"func _commit_settings_mode_exit",
		"func _settings_mode_show_intent",
		"settings_mode_owner.show_intent",
		"const TrainingMode = preload(\"res://scripts/modes/training_mode.gd\")",
		"var training_mode_owner: TrainingMode",
		"training_mode_owner.bind(self, scout_controller)",
		"func _commit_training_mode_enter",
		"func _commit_training_mode_exit",
		"func _training_config_intent",
		"training_mode_owner.config_intent",
		"func _training_scout_show_intent",
		"training_mode_owner.scout_show_intent",
		"func _ready() -> void:",
		"_initialize_hot_path_state_layer",
		"_show_menu",
	], "main.gd app-root baseline")

	var inline_guard := _require_file(INLINE_GUARD_PATH)
	_require_tokens(inline_guard, [
		"ALLOWED_INLINE_CLASSES",
		"EXTRACTED_INLINE_CLASSES",
		"New inline class in main.gd must be extracted",
	], "main inline class guard")

	var manifest := _require_file(MANIFEST_PATH)
	_require_tokens(manifest, [
		"app_root_boundary_probe",
		"app_mode_host_contract_probe",
		"battle_state_contract_probe",
		"battle_mode_contract_probe",
		"menu_mode_contract_probe",
		"team_edit_mode_contract_probe",
		"saved_units_mode_contract_probe",
		"settings_mode_contract_probe",
		"training_mode_contract_probe",
		"main_file_extraction_contract_probe",
		"main_inline_class_guard_probe",
		"view_extraction_contract_probe",
		"effect_extraction_contract_probe",
	], "probe manifest")

	print("APP_ROOT_BOUNDARY_PROBE ok")
	quit(0)
