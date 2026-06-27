extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const LegalStarterBlueprintFixture := preload("res://tools/fixtures/legal_starter_blueprint_fixture.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _find_non_soul_special(main, role_key: String) -> int:
	var catalog: Array = main._catalog_for(role_key, "special")
	for i in range(catalog.size()):
		if not (catalog[i] is Dictionary):
			continue
		var part: Dictionary = catalog[i]
		var kind := String(part.get("kind", part.get("identity_kind", part.get("software_kind", "")))).strip_edges().to_lower()
		if kind != "" and kind != "soul":
			return i
	return -1


func _without_special_payloads(raw_payloads: Array) -> Array:
	var payloads: Array = []
	for raw_payload in raw_payloads:
		if not (raw_payload is Dictionary):
			continue
		var payload: Dictionary = Dictionary(raw_payload).duplicate(true)
		if payload.has("special") or String(payload.get("kind", "")).strip_edges().to_lower() == "special":
			continue
		payloads.append(payload)
	return payloads


func _remove_saved_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor(true)

	var legal_bp := LegalStarterBlueprintFixture.build(main, "Identity Gate Legal")
	_require(not legal_bp.is_empty(), "Could not build legal starter fixture.")
	if failed:
		quit(1)
		return

	var legal_note := main._training_blueprint_illegal_note(1, "hero", legal_bp)
	_require(legal_note == "", "Legal starter should remain eligible after main legality service integration, got %s" % legal_note)

	var non_soul_special := _find_non_soul_special(main, "hero")
	_require(non_soul_special >= 0, "Hero special catalog should include a non-Soul entry for the rejection fixture.")
	if failed:
		quit(1)
		return

	var invalid_bp: Dictionary = legal_bp.duplicate(true)
	invalid_bp["name"] = "Identity Gate Invalid"
	invalid_bp["unit_name"] = "Identity Gate Invalid"
	invalid_bp["special"] = non_soul_special
	invalid_bp["slot_payloads"] = _without_special_payloads(Array(invalid_bp.get("slot_payloads", [])))

	var invalid_note := main._training_blueprint_illegal_note(1, "hero", invalid_bp)
	_require(invalid_note.find("hero_soul_count") >= 0, "Hero without a Soul should be blocked by the service code, got %s" % invalid_note)
	if failed:
		quit(1)
		return

	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = invalid_bp
	main.editor_canvas_mode = "blank"
	var invalid_path := "%s/identity_gate_invalid_%d.json" % [MainScene.SAVED_UNITS_DIR, int(Time.get_ticks_msec())]
	var invalid_result := main._save_editor_current_unit_to_library_named("Identity Gate Invalid", invalid_path, true)
	if invalid_result != "":
		_remove_saved_file(invalid_path)
		_fail("Identity-invalid unit should be rejected before write, got %s" % invalid_result)
	if FileAccess.file_exists(invalid_path):
		_remove_saved_file(invalid_path)
		_fail("Identity-invalid unit created a library file.")

	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_LEGALITY_MAIN_GATE_PROBE ok note=%s" % invalid_note)
	quit(0)
