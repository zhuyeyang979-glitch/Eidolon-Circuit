extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const LegalStarterBlueprintFixture := preload("res://tools/fixtures/legal_starter_blueprint_fixture.gd")

var failures: Array[String] = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor(true)
	var player_id: int = main._editor_player()
	if not main.blueprints.has(player_id):
		main.blueprints[player_id] = main._blank_player_roster()
	if not main.active_roster_indices.has(player_id):
		main.active_roster_indices[player_id] = {"hero": 0, "puppet": 0, "barrier": 0}
	var bp := LegalStarterBlueprintFixture.build(main, "Load Hover Probe")
	if bp.is_empty():
		_fail("Could not build legal load-hover fixture.")
	else:
		main.editor_working_blueprint = bp
		main.editor_working_role_key = "hero"
		main.editor_canvas_mode = "blank"
	var path := "user://saved_units/probe_editor_load_hover.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var saved_path := main._save_editor_current_unit_to_library(path) if failures.is_empty() else ""
	if saved_path != path:
		_fail("Could not save legal load-hover fixture.")
	main.editor_panel_mode = "load"
	main.editor_load_mode = "unit"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_unit_indices["hero"] = 0
	main._update_editor_ui()
	var entries: Array = main._editor_load_entries()
	var target_index := -1
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		if String(entry.get("path", "")) == path:
			target_index = i
			break
	if target_index < 0:
		_fail("Saved load-hover fixture was not visible in unit entries.")
	var page_size: int = maxi(1, main.editor_load_card_buttons.size())
	main.editor_load_page = maxi(0, int(floori(float(maxi(0, target_index)) / float(page_size))))
	main._update_editor_load_card_buttons("hero")
	main._hover_editor_load_card(maxi(0, target_index) % page_size)
	if int(main.editor_unit_indices["hero"]) != 0:
		_fail("Hovering a load card changed the active canvas page.")
	if main.editor_unit_hover_view == null or not main.editor_unit_hover_view.visible:
		_fail("Hovering a load card did not show the unit thumbnail/detail preview.")
	main.editor_load_page = 9
	main._update_editor_load_card_buttons("hero")
	var max_page := maxi(0, int(ceilf(float(entries.size()) / float(maxi(1, main.editor_load_card_buttons.size())))) - 1)
	if main.editor_load_page != max_page:
		_fail("Load card pagination did not clamp to the last valid page.")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not failures.is_empty():
		print("EDITOR_LOAD_HOVER_PROBE failed count=%d entries=%d" % [failures.size(), entries.size()])
		quit(1)
		return
	print("EDITOR_LOAD_HOVER_PROBE hover_keeps_unit=%d preview=%s page=%d/%d entries=%d" % [
		int(main.editor_unit_indices["hero"]),
		str(main.editor_unit_hover_view.visible),
		main.editor_load_page + 1,
		max_page + 1,
		entries.size(),
	])
	quit()
