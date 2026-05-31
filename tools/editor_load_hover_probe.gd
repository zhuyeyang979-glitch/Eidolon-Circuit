extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_panel_mode = "load"
	main.editor_load_mode = "team"
	main.editor_load_page = 0
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_unit_indices["hero"] = 0
	main._update_editor_ui()
	main._hover_editor_load_card(1)
	if int(main.editor_unit_indices["hero"]) != 0:
		_fail("Hovering a load card changed the active canvas page.")
	if main.editor_unit_hover_view == null or not main.editor_unit_hover_view.visible:
		_fail("Hovering a load card did not show the unit thumbnail/detail preview.")
	var entries: Array = main._editor_load_entries()
	main.editor_load_page = 9
	main._update_editor_load_card_buttons("hero")
	var max_page := maxi(0, int(ceilf(float(entries.size()) / float(maxi(1, main.editor_load_card_buttons.size())))) - 1)
	if main.editor_load_page != max_page:
		_fail("Load card pagination did not clamp to the last valid page.")
	print("EDITOR_LOAD_HOVER_PROBE hover_keeps_unit=%d preview=%s page=%d/%d entries=%d" % [
		int(main.editor_unit_indices["hero"]),
		str(main.editor_unit_hover_view.visible),
		main.editor_load_page + 1,
		max_page + 1,
		entries.size(),
	])
	quit()
