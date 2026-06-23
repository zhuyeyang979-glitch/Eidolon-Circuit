extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failures: Array[String] = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _builtin_entries(entries: Array) -> Array:
	var result: Array = []
	for raw_entry in entries:
		if raw_entry is Dictionary and bool(Dictionary(raw_entry).get("builtin_hero_preset", false)):
			result.append(Dictionary(raw_entry))
	return result


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_panel_mode = "load"
	main.editor_load_mode = "unit"
	main.editor_load_page = 0
	main._update_editor_ui()

	var entries: Array = main._editor_load_entries()
	var presets := _builtin_entries(entries)
	_assert(presets.size() >= 3, "Hero load panel should expose at least three built-in hero presets.")

	var seen_names := {}
	for raw_entry in presets:
		var entry: Dictionary = raw_entry
		var name := String(entry.get("unit_name", ""))
		_assert(name.strip_edges() != "", "Built-in hero preset should expose a display name.")
		_assert(not seen_names.has(name), "Built-in hero preset names should be unique: %s." % name)
		seen_names[name] = true
		_assert(bool(entry.get("unit_library", false)), "Built-in hero preset should reuse unit-library load behavior: %s." % name)
		_assert(String(entry.get("role", "")) == "hero", "Built-in hero preset should be a hero entry: %s." % name)
		_assert(String(entry.get("path", "")).begins_with("builtin://hero_presets/"), "Built-in hero preset should use a virtual builtin path: %s." % name)
		_assert(entry.get("blueprint", {}) is Dictionary, "Built-in hero preset should include a blueprint: %s." % name)
		var bp: Dictionary = Dictionary(entry.get("blueprint", {}))
		_assert(String(bp.get("role", "")) == "hero", "Built-in preset blueprint should keep hero role: %s." % name)
		_assert(bool(bp.get("builtin_hero_preset", false)), "Built-in preset blueprint should be marked as built-in: %s." % name)
		var nodes: Array = Array(Dictionary(bp.get("custom_topology", {})).get("nodes", []))
		_assert(not nodes.is_empty(), "Built-in hero preset should include assembled topology nodes: %s." % name)
		_assert(Array(bp.get("slot_payloads", [])).size() >= 4, "Built-in hero preset should include installed payloads: %s." % name)
		_assert(Array(bp.get("module_bindings", [])).size() >= 1, "Built-in hero preset should include module bindings: %s." % name)
		var note := main._saved_unit_entry_illegal_note(entry)
		_assert(note == "", "Built-in hero preset should be immediately legal, got %s for %s." % [note, name])

	if not presets.is_empty():
		var first: Dictionary = presets[0]
		var target_index := entries.find(first)
		_assert(target_index >= 0, "First built-in preset should be selectable from editor entries.")
		var page_size: int = maxi(1, main.editor_load_card_buttons.size())
		main.editor_load_page = int(floori(float(target_index) / float(page_size)))
		main._select_editor_load_card(target_index % page_size)
		var loaded: Dictionary = main._editor_current_blueprint()
		_assert(String(loaded.get("unit_name", "")) == String(first.get("unit_name", "")), "Selecting a built-in preset should load it into the temporary canvas.")
		_assert(bool(loaded.get("builtin_hero_preset", false)), "Loaded built-in preset should keep its built-in marker.")
		_assert(String(main.editor_source_saved_unit_path).begins_with("builtin://hero_presets/"), "Loaded built-in preset should keep a virtual source path.")
		_assert(not Array(Dictionary(loaded.get("custom_topology", {})).get("nodes", [])).is_empty(), "Loaded built-in preset should keep assembled topology.")

	if not failures.is_empty():
		print("PREBUILT_HERO_PRESETS_PROBE failed count=%d entries=%d presets=%d" % [failures.size(), entries.size(), presets.size()])
		quit(1)
		return
	print("PREBUILT_HERO_PRESETS_PROBE ok presets=%d" % presets.size())
	quit()
