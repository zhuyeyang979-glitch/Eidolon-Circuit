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
	var entries: Array = main._editor_catalog_entries("hero", "muscle")
	var pool_size := int(main.editor_catalog_buttons.size())
	if pool_size <= 0:
		_fail("Catalog card pool is missing.")
		return
	if pool_size > 36:
		_fail("Catalog keeps too many live card controls: %d" % pool_size)
		return
	if entries.size() > pool_size and pool_size >= entries.size():
		_fail("Catalog appears to instantiate every entry instead of a visible pool.")
		return
	var visible_count := 0
	for button in main.editor_catalog_buttons:
		if button != null and button.visible:
			visible_count += 1
	if visible_count > pool_size:
		_fail("Visible catalog card count exceeds pool size.")
		return
	print("teamedit_virtual_catalog_probe ok entries=%d pool=%d visible=%d" % [entries.size(), pool_size, visible_count])
	quit(0)
