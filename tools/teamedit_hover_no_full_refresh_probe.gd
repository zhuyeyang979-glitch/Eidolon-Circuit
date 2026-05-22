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
	main.editor_update_ui_count = 0
	main.editor_visual_refresh_count = 0
	main.editor_compute_unit_stats_count = 0
	var part := main._selected_component("hero", "muscle", 0)
	main._show_editor_part_hover("muscle", 0, part)
	var stats_after_first := int(main.editor_compute_unit_stats_count)
	for i in range(12):
		main._show_editor_part_hover("muscle", 0, part)
	if int(main.editor_update_ui_count) != 0:
		_fail("Hover triggered full editor UI update.")
	if int(main.editor_visual_refresh_count) != 0:
		_fail("Hover triggered visual board refresh.")
	if int(main.editor_compute_unit_stats_count) != stats_after_first:
		_fail("Same hover target recomputed stats.")
	print("TEAMEDIT_HOVER_NO_FULL_REFRESH_PROBE ok stats=%d" % stats_after_first)
	quit()
