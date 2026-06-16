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
	main._update_editor_ui(true)
	var retained_count := 0
	var visible_buttons := 0
	for raw_button in main.editor_catalog_buttons:
		if raw_button == null or not (raw_button is MainScene.PartCatalogCardButton):
			continue
		var button: MainScene.PartCatalogCardButton = raw_button
		if button.visible:
			visible_buttons += 1
		if button.retained_item != null and button.retained_item.visible:
			retained_count += 1
		if button.text != "":
			_fail("Catalog button still owns visible text instead of retained body texture.")
			return
	if visible_buttons <= 0:
		_fail("No visible catalog buttons to validate.")
		return
	if retained_count != visible_buttons:
		_fail("Visible catalog cards are not fully retained: %d/%d." % [retained_count, visible_buttons])
		return
	var source := FileAccess.get_file_as_string("res://scripts/views/catalog/part_catalog_card_button.gd")
	if source.is_empty() or source.find("class_name PartCatalogCardButton") < 0:
		_fail("Extracted PartCatalogCardButton source missing.")
		return
	var draw_start := source.find("func _draw() -> void:")
	var draw_end := source.find("func _draw_art", draw_start)
	var draw_block := source.substr(draw_start, max(0, draw_end - draw_start))
	if draw_block.contains("draw_rect") or draw_block.contains("draw_texture"):
		_fail("PartCatalogCardButton._draw still paints card body directly.")
		return
	print("CATALOG_CARD_RETAINED_ITEM_PROBE ok retained=%d" % retained_count)
	quit(0)
