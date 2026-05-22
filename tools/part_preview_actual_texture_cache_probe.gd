extends SceneTree


const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _draw_total(main) -> int:
	var total := 0
	for button in main.editor_catalog_buttons:
		if button != null and button.preview_icon != null:
			total += int(button.preview_icon.renderer_draw_count)
	return total


func _apply_total(main) -> int:
	var total := 0
	for button in main.editor_catalog_buttons:
		if button != null and button.preview_icon != null:
			total += int(button.preview_icon.set_preview_apply_count)
	return total


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if main_source.contains("PartCatalogCardButton._draw still synchronizes preview state"):
		_fail("Probe source unexpectedly embedded in main.gd.")
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_panel_mode = "parts"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	main._update_editor_ui()
	var draw_before := _draw_total(main)
	var apply_before := _apply_total(main)
	for i in range(8):
		main._update_editor_catalog_buttons("hero", main._editor_current_blueprint())
		for button in main.editor_catalog_buttons:
			if button != null:
				button.queue_redraw()
		main._tick_editor_visuals(1.0 / 60.0)
	var draw_after := _draw_total(main)
	var apply_after := _apply_total(main)
	if draw_after != draw_before:
		_fail("Repeated catalog updates/redraws invoked preview renderer: %d -> %d" % [draw_before, draw_after])
	if apply_after != apply_before:
		_fail("Repeated catalog updates reapplied preview state: %d -> %d" % [apply_before, apply_after])
	print("PART_PREVIEW_ACTUAL_TEXTURE_CACHE_PROBE ok draw=%d apply=%d" % [draw_after, apply_after])
	quit(0)
