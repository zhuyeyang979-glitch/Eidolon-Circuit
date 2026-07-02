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
	main._update_editor_ui(true)
	main._refresh_editor_visual_views()
	var updates := int(main.editor_side_preview_update_count)
	main._refresh_editor_visual_views()
	if int(main.editor_side_preview_update_count) != updates:
		_fail("Board refresh updated side preview without selected part change.")
		return
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("booster")
	main.selected_component = main._selected_component("hero", "booster", 0)
	main._refresh_editor_visual_views()
	if int(main.editor_side_preview_update_count) <= updates:
		_fail("Selected part change did not update side preview.")
		return
	print("EDITOR_SIDE_PREVIEW_DIRTY_PROBE ok updates=%d noop=%d" % [
		int(main.editor_side_preview_update_count),
		int(main.editor_side_preview_noop_count),
	])
	quit(0)
