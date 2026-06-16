extends SceneTree

const CARD_BUTTON_PATH := "res://scripts/views/catalog/part_catalog_card_button.gd"
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _preview_draw_total(main) -> int:
	var total := 0
	for button in main.editor_catalog_buttons:
		if button != null and button.preview_icon != null:
			total += int(button.preview_icon.renderer_draw_count)
	return total


func _init() -> void:
	var source := FileAccess.get_file_as_string(CARD_BUTTON_PATH)
	if source.is_empty() or source.find("class_name PartCatalogCardButton") < 0:
		_fail("Extracted PartCatalogCardButton source missing.")
	var card_draw_pos := source.find("func _draw() -> void:")
	var draw_art_pos := source.find("func _draw_art", card_draw_pos)
	var card_draw_block := source.substr(card_draw_pos, max(0, draw_art_pos - card_draw_pos))
	if card_draw_block.contains("AssemblyBoardRenderer.draw_part_preview"):
		_fail("PartCatalogCardButton._draw still calls full part preview renderer.")
	if card_draw_block.contains("_sync_preview_icon"):
		_fail("PartCatalogCardButton._draw still synchronizes preview state during redraw.")
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_panel_mode = "parts"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	main._update_editor_ui()
	var draw_before := _preview_draw_total(main)
	for button in main.editor_catalog_buttons:
		if button != null:
			button.queue_redraw()
	for i in range(20):
		main._tick_editor_visuals(1.0 / 60.0)
	var draw_after := _preview_draw_total(main)
	if draw_after != draw_before:
		_fail("Parent card redraws forced preview renderer redraws: before=%d after=%d" % [draw_before, draw_after])
	var apply_total := 0
	for button in main.editor_catalog_buttons:
		if button != null and button.preview_icon != null:
			apply_total += int(button.preview_icon.set_preview_apply_count)
	print("CATALOG_CARD_REDRAW_BUDGET_PROBE ok preview_draw=%d preview_apply=%d" % [draw_after, apply_total])
	quit()
