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
	main._update_editor_ui(true)
	main._refresh_editor_visual_views()
	var rebuilds := int(main.editor_board_base_snapshot_rebuild_count)
	var refreshes := int(main.editor_visual_refresh_count)
	var part := main._selected_component("hero", "muscle", 0)
	main._show_editor_part_hover("muscle", 0, part)
	var hover_refresh := int(main.editor_hover_preview_refresh_count)
	for i in range(40):
		main._show_editor_part_hover("muscle", 0, part)
		main._tick_editor_visuals(1.0 / 60.0)
	if int(main.editor_hover_preview_refresh_count) != hover_refresh:
		_fail("Repeated same hover refreshed hover preview.")
	if int(main.editor_board_base_snapshot_rebuild_count) != rebuilds:
		_fail("Repeated same hover rebuilt board base snapshot.")
	if int(main.editor_visual_refresh_count) != refreshes:
		_fail("Repeated same hover refreshed board visuals.")
	print("TEAMEDIT_HOVER_FRAME_BUDGET_PROBE ok refreshes=%d rebuilds=%d" % [int(main.editor_visual_refresh_count), int(main.editor_board_base_snapshot_rebuild_count)])
	quit(0)
