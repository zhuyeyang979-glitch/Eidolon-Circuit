extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const LegalStarterBlueprintFixture := preload("res://tools/fixtures/legal_starter_blueprint_fixture.gd")

const MAIN_PATH := "res://scripts/main.gd"
const SERVICE_PATH := "res://scripts/services/unit_editor_legality_service.gd"
const MANIFEST_PATH := "res://tools/probe_manifest.json"
const ROADMAP_PATH := "res://docs/plans/2026-06-24-unit-editor-legality-roadmap.md"

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))


func _json_stable(value: Variant) -> String:
	return JSON.stringify(value, "\t", false)


func _remove_saved_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _init() -> void:
	_static_contract_checks()
	_runtime_save_contract_checks()
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_SCHEMA_INVARIANCE_PROBE ok schema=%s" % MainScene.SAVED_UNIT_SCHEMA_VERSION)
	quit(0)


func _static_contract_checks() -> void:
	var main_source := _read(MAIN_PATH)
	_require(main_source.find("const SAVED_UNIT_SCHEMA_VERSION = \"momentum_chain_v3\"") >= 0, "Saved-unit schema version changed without a migration plan.")
	_require(main_source.find("const SAVE_KIND_SINGLE_UNIT = \"single_unit\"") >= 0, "Single-unit save kind changed.")
	_require(main_source.find("const SAVE_KIND_PUPPET_GROUP = \"puppet_group\"") >= 0, "Puppet-group save kind changed.")

	var service_source := _read(SERVICE_PATH)
	for forbidden in [
		"SAVED_UNIT_SCHEMA_VERSION",
		"schema_version",
		"edge_snap_version",
		"legacy_rejected",
		"migration",
		"[\"custom_topology\"] =",
		".erase(\"custom_topology\")",
	]:
		_require(service_source.find(forbidden) < 0, "UnitEditorLegalityService must not write schema/topology migration fields, found token: %s" % forbidden)

	var manifest := _read(MANIFEST_PATH)
	_require(manifest.find("unit_editor_schema_invariance_probe") >= 0, "Probe manifest should register the schema invariance guard.")

	var roadmap := _read(ROADMAP_PATH)
	_require(roadmap.find("tools/unit_editor_schema_invariance_probe.gd") >= 0, "Roadmap should cite the schema invariance guard.")
	_require(roadmap.find("saved-unit schema unchanged") >= 0, "Roadmap should explicitly preserve saved-unit schema.")
	_require(roadmap.find("legacy topology keys") >= 0, "Roadmap should explicitly preserve legacy topology keys.")


func _runtime_save_contract_checks() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor(true)

	var legal_bp := LegalStarterBlueprintFixture.build(main, "Schema Invariance Legal")
	_require(not legal_bp.is_empty(), "Could not build legal starter fixture.")
	if failed:
		main.queue_free()
		return

	legal_bp["schema_version"] = "legacy_probe_input"
	legal_bp["save_kind"] = "legacy_probe_input_kind"
	var topology_before := _json_stable(legal_bp.get("custom_topology", {}))
	var source_before := _json_stable(legal_bp)
	var report: Dictionary = main._unit_editor_legality_report("hero", legal_bp)
	_require(bool(report.get("valid", false)), "Legality report should accept the legal starter: %s" % str(report))
	_require(_json_stable(legal_bp) == source_before, "Legality report should not mutate the source blueprint.")
	_require(_json_stable(legal_bp.get("custom_topology", {})) == topology_before, "Legality report should not mutate custom_topology.")
	_require(String(legal_bp.get("schema_version", "")) == "legacy_probe_input", "Legality report should not rewrite blueprint schema_version.")

	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = legal_bp
	main.editor_canvas_mode = "blank"
	var save_path := "%s/schema_invariance_%d.json" % [MainScene.SAVED_UNITS_DIR, int(Time.get_ticks_msec())]
	var result := main._save_editor_current_unit_to_library_named("Schema Invariance Legal", save_path, true)
	_require(result == save_path and FileAccess.file_exists(save_path), "Legal starter should save with the current schema, got %s" % result)
	if result == save_path and FileAccess.file_exists(save_path):
		var payload_raw := FileAccess.get_file_as_string(ProjectSettings.globalize_path(save_path))
		var parsed = JSON.parse_string(payload_raw)
		_require(parsed is Dictionary, "Saved unit payload should be JSON dictionary.")
		if parsed is Dictionary:
			var payload: Dictionary = parsed
			var blueprint: Dictionary = Dictionary(payload.get("blueprint", {})) if payload.get("blueprint", {}) is Dictionary else {}
			var topology: Dictionary = Dictionary(blueprint.get("custom_topology", {})) if blueprint.get("custom_topology", {}) is Dictionary else {}
			_require(String(payload.get("schema_version", "")) == MainScene.SAVED_UNIT_SCHEMA_VERSION, "Payload schema should stay at the current saved-unit schema.")
			_require(String(blueprint.get("schema_version", "")) == MainScene.SAVED_UNIT_SCHEMA_VERSION, "Blueprint schema should stay at the current saved-unit schema.")
			_require(String(payload.get("save_kind", "")) == MainScene.SAVE_KIND_SINGLE_UNIT, "Payload save kind should remain single_unit.")
			_require(blueprint.has("custom_topology"), "Saved blueprint should keep custom_topology.")
			_require(topology.has("nodes") and topology.has("edges") and topology.has("edge_snap_version"), "Saved custom_topology should keep nodes/edges/edge_snap_version keys.")
			_require(not payload.has("unit_editor_legality_report") and not blueprint.has("unit_editor_legality_report"), "Saved payload should not persist transient legality reports.")
			_require(not payload.has("blocking_codes") and not blueprint.has("blocking_codes"), "Saved payload should not persist transient blocking codes.")
		_remove_saved_file(save_path)
	main.queue_free()
