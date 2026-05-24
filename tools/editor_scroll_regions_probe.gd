extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _wheel(button_index: int, pos: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = true
	event.position = pos
	return event


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._select_editor_part_group("terminal_weapon")
	main.flush_editor_dirty(5000)
	var initial_zoom := float(main.editor_board_zoom)
	if main.editor_stats_rail_view == null:
		_fail("Stats rail missing.")
	if main.editor_stats_rail_view.mouse_filter != Control.MOUSE_FILTER_STOP:
		_fail("Stats rail must consume wheel events instead of passing them to board zoom.")
	var rail_entries: Array = []
	for i in range(24):
		rail_entries.append({"label": "STAT%d" % i, "value": float(i + 1), "preview": float(i + 1), "max_value": 32.0, "unit": "", "illegal": false})
	main.editor_stats_rail_view.set_stats(rail_entries, "TEST", "RULE OK", false, "en")
	main.editor_stats_rail_view._gui_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN, Vector2(20.0, 120.0)))
	if absf(float(main.editor_board_zoom) - initial_zoom) > 0.0001:
		_fail("Dashboard wheel changed board zoom.")
	if float(main.editor_stats_rail_view.scroll_offset) <= 0.0:
		_fail("Dashboard wheel did not scroll stats rail.")
	if main.editor_catalog_buttons.is_empty() or not main.editor_catalog_buttons[0].has_method("_gui_input"):
		_fail("Catalog card missing.")
	var page_before := int(main.editor_catalog_page)
	var card = main.editor_catalog_buttons[0]
	card._gui_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN, card.size * 0.5))
	if absf(float(main.editor_board_zoom) - initial_zoom) > 0.0001:
		_fail("Catalog card wheel changed board zoom.")
	if int(main.editor_catalog_page) <= page_before:
		_fail("Catalog card wheel did not turn to the next page.")
	print("EDITOR_SCROLL_REGIONS_PROBE ok rail_scroll=%.1f page=%d zoom=%.2f" % [float(main.editor_stats_rail_view.scroll_offset), int(main.editor_catalog_page), float(main.editor_board_zoom)])
	quit()
