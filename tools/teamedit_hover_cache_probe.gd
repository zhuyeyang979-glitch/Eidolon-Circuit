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
	main.editor_hover_preview_refresh_count = 0
	main.editor_visual_refresh_count = 0
	var part := main._selected_component("hero", "muscle", 0)
	main._show_editor_part_hover("muscle", 0, part)
	var refresh_after_first := int(main.editor_hover_preview_refresh_count)
	var visual_after_first := int(main.editor_visual_refresh_count)
	main._show_editor_part_hover("muscle", 0, part)
	if refresh_after_first != 1:
		_fail("First hover did not refresh exactly once: %d" % refresh_after_first)
	if int(main.editor_hover_preview_refresh_count) != refresh_after_first:
		_fail("Same hover target recomputed preview.")
	if int(main.editor_visual_refresh_count) != visual_after_first:
		_fail("Hover refresh triggered visual board redraw.")
	print("TEAMEDIT_HOVER_CACHE_PROBE ok refresh=%d visual=%d" % [refresh_after_first, visual_after_first])
	quit()
