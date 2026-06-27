extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const LegalStarterBlueprintFixture := preload("res://tools/fixtures/legal_starter_blueprint_fixture.gd")

const MAIN_PATH := "res://scripts/main.gd"
const SERVICE_PATH := "res://scripts/services/unit_editor_legality_service.gd"
const MANIFEST_PATH := "res://tools/probe_manifest.json"
const ROADMAP_PATH := "res://docs/plans/2026-06-24-unit-editor-legality-roadmap.md"

const TRANSIENT_LEGALITY_SAVE_KEYS := [
	"unit_editor_legality_report",
	"blocking_codes",
	"blocking_notes",
]

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


func _contains_key(value, key: String) -> bool:
	if value is Dictionary:
		var dict: Dictionary = value
		if dict.has(key):
			return true
		for raw_key in dict.keys():
			if _contains_key(dict[raw_key], key):
				return true
	if value is Array:
		for item in Array(value):
			if _contains_key(item, key):
				return true
	return false


func _assert_no_transient_legality_fields(label: String, value) -> void:
	for key in TRANSIENT_LEGALITY_SAVE_KEYS:
		_require(not _contains_key(value, key), "%s should not persist transient legality key %s: %s" % [label, key, str(value)])


func _pollute_transient_legality_fields(unit_bp: Dictionary) -> Dictionary:
	var polluted := unit_bp.duplicate(true)
	polluted["unit_editor_legality_report"] = {
		"valid": false,
		"blocking_codes": ["probe_transient_legality"],
		"blocking_notes": ["probe_transient_legality"],
	}
	polluted["blocking_codes"] = ["probe_transient_legality"]
	polluted["blocking_notes"] = ["probe_transient_legality"]
	return polluted


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

	legal_bp = _pollute_transient_legality_fields(legal_bp)
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
			_assert_no_transient_legality_fields("Saved single-unit payload", payload)
		_remove_saved_file(save_path)
	_runtime_puppet_group_save_contract_checks(main)
	main.queue_free()


func _runtime_puppet_group_save_contract_checks(main) -> void:
	var puppet_a := _pollute_transient_legality_fields(_minimal_puppet(main, "Schema Invariance Puppet A"))
	var puppet_b := _pollute_transient_legality_fields(_minimal_puppet(main, "Schema Invariance Puppet B"))
	var selection := [
		{"unit_library": true, "role": "puppet", "path": "probe://schema_puppet_a", "unit_name": "Schema Invariance Puppet A", "blueprint": puppet_a},
		{"unit_library": true, "role": "puppet", "path": "probe://schema_puppet_b", "unit_name": "Schema Invariance Puppet B", "blueprint": puppet_b},
	]
	var group_path: String = main._save_puppet_group_from_saved_unit_selection("Schema Invariance Puppet Group", selection)
	_require(group_path != "" and FileAccess.file_exists(group_path), "Puppet group should save with the current schema, got %s" % group_path)
	if group_path == "" or not FileAccess.file_exists(group_path):
		return
	var payload_raw := FileAccess.get_file_as_string(ProjectSettings.globalize_path(group_path))
	var parsed = JSON.parse_string(payload_raw)
	_require(parsed is Dictionary, "Puppet group payload should be JSON dictionary.")
	if parsed is Dictionary:
		var payload: Dictionary = parsed
		var blueprint: Dictionary = Dictionary(payload.get("blueprint", {})) if payload.get("blueprint", {}) is Dictionary else {}
		var group_blueprints: Array = Array(payload.get("puppet_group_blueprints", []))
		_require(String(payload.get("schema_version", "")) == MainScene.SAVED_UNIT_SCHEMA_VERSION, "Puppet group payload schema should stay at the current saved-unit schema.")
		_require(String(payload.get("save_kind", "")) == MainScene.SAVE_KIND_PUPPET_GROUP, "Puppet group payload save kind should remain puppet_group.")
		_require(String(blueprint.get("schema_version", "")) == MainScene.SAVED_UNIT_SCHEMA_VERSION, "Puppet group blueprint schema should stay at the current saved-unit schema.")
		_require(String(blueprint.get("save_kind", "")) == MainScene.SAVE_KIND_PUPPET_GROUP, "Puppet group blueprint save kind should remain puppet_group.")
		_require(group_blueprints.size() == 2, "Puppet group payload should keep two member blueprints.")
		for i in range(group_blueprints.size()):
			_require(group_blueprints[i] is Dictionary, "Puppet group member %d should be a dictionary." % i)
			if group_blueprints[i] is Dictionary:
				var member: Dictionary = group_blueprints[i]
				var topology: Dictionary = Dictionary(member.get("custom_topology", {})) if member.get("custom_topology", {}) is Dictionary else {}
				_require(String(member.get("schema_version", "")) == MainScene.SAVED_UNIT_SCHEMA_VERSION, "Puppet group member %d schema should stay current." % i)
				_require(String(member.get("save_kind", "")) == MainScene.SAVE_KIND_SINGLE_UNIT, "Puppet group member %d should remain a single unit." % i)
				_require(topology.has("nodes") and topology.has("edges") and topology.has("edge_snap_version"), "Puppet group member %d should keep custom_topology keys." % i)
		_assert_no_transient_legality_fields("Saved puppet-group payload", payload)
	_remove_saved_file(group_path)


func _minimal_puppet(main, unit_name: String) -> Dictionary:
	var core_index: int = int(main._component_index_by_name("puppet", "muscle", "FLOATING BIT CORE", 95))
	var node: Dictionary = main._topology_component_node(0, "CORE", Vector2(0.5, 0.5), "muscle", core_index)
	return {
		"name": unit_name,
		"unit_name": unit_name,
		"role": "puppet",
		"archetype": "custom",
		"special": 0,
		"joint": 0,
		"limb_muscle": 0,
		"muscle": core_index,
		"booster": 0,
		"engine": 0,
		"cooling": 0,
		"module": 0,
		"blank_canvas": false,
		"custom_topology": {"nodes": [node], "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION},
		"slot_payloads": [],
		"purchased_parts": {},
	}
