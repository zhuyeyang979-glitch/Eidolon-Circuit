extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if MainScene.CATALOG_CARD_TITLE_FONT_SIZE < 11:
		_fail("Catalog card title font should be at least 11px.")
	if MainScene.CATALOG_CARD_SIMPLE_TITLE_FONT_SIZE < 12:
		_fail("Simple catalog card title font should be at least 12px.")
	if MainScene.CATALOG_CARD_LINE_FONT_SIZE < 9:
		_fail("Catalog card body lines should be at least 9px.")
	if MainScene.CATALOG_CARD_TEXT_PLATE_ALPHA < 0.55:
		_fail("Catalog card text plate is too transparent.")
	if MainScene.CATALOG_CARD_BODY_TEXTURE_STYLE_REVISION < 2:
		_fail("Catalog card body texture style revision must invalidate older low-contrast cache entries.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var body_source := FileAccess.get_file_as_string("res://scripts/views/catalog/catalog_card_body_texture_render_canvas.gd")
	var retained_source := FileAccess.get_file_as_string("res://scripts/views/catalog/catalog_card_retained_item.gd")
	if not main_source.contains("CATALOG_CARD_TEXT_PLATE_ALPHA") or not body_source.contains("CATALOG_CARD_TEXT_PLATE_ALPHA") or not retained_source.contains("CATALOG_CARD_TEXT_PLATE_ALPHA"):
		_fail("Catalog card text should draw a contrast plate.")
	if not body_source.contains("class_name CatalogCardBodyTextureRenderCanvas") or not retained_source.contains("class_name CatalogCardRetainedItem"):
		_fail("Catalog card retained/body texture paths are missing.")
	print("CATALOG_CARD_TEXT_READABILITY_PROBE ok title=%d line=%d plate=%.2f rev=%d" % [
		MainScene.CATALOG_CARD_TITLE_FONT_SIZE,
		MainScene.CATALOG_CARD_LINE_FONT_SIZE,
		MainScene.CATALOG_CARD_TEXT_PLATE_ALPHA,
		MainScene.CATALOG_CARD_BODY_TEXTURE_STYLE_REVISION,
	])
	quit()
