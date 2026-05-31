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
	main.editor_panel_mode = "parts"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	main._update_editor_ui()
	main.editor_visual_refresh_count = 0
	main.editor_compute_unit_stats_count = 0
	var board = main.assembly_board_view
	var apply_before := int(board.set_board_apply_count)
	for i in range(180):
		main._tick_editor_visuals(1.0 / 60.0)
	if int(main.editor_visual_refresh_count) != 0:
		_fail("Idle TeamEdit frames refreshed visuals %d times." % int(main.editor_visual_refresh_count))
	if int(board.set_board_apply_count) != apply_before:
		_fail("Idle TeamEdit frames applied board redraws.")
	var part := main._selected_component("hero", "muscle", 0)
	main._show_editor_part_hover("muscle", 0, part)
	var hover_refreshes := int(main.editor_hover_preview_refresh_count)
	var visual_after_hover := int(main.editor_visual_refresh_count)
	for i in range(30):
		main._show_editor_part_hover("muscle", 0, part)
		main._tick_editor_visuals(1.0 / 60.0)
	if int(main.editor_hover_preview_refresh_count) != hover_refreshes:
		_fail("Repeated same hover recomputed preview.")
	if int(main.editor_visual_refresh_count) != visual_after_hover:
		_fail("Repeated same hover refreshed board visuals.")
	print("TEAMEDIT_REAL_FRAME_BUDGET_PROBE ok idle_visual=%d board_apply=%d hover=%d" % [int(main.editor_visual_refresh_count), int(board.set_board_apply_count), int(main.editor_hover_preview_refresh_count)])
	quit()
