extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _class_block(source: String, cls_name: String, next_cls_name: String) -> String:
	var start := source.find("class %s" % cls_name)
	if start < 0:
		return ""
	var end := source.find("class %s" % next_cls_name, start + 1)
	if end < 0:
		end = source.length()
	return source.substr(start, end - start)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var retained := FileAccess.get_file_as_string("res://scripts/views/catalog/catalog_card_retained_item.gd")
	if retained == "":
		_fail("CatalogCardRetainedItem class missing.")
	if retained.contains("draw_texture_rect(body_texture"):
		_fail("Retained catalog cards still draw low-resolution body text texture.")
	if retained.contains("CatalogCardBodyTextureCache.request_preview"):
		_fail("Retained catalog cards still request cached body text textures.")
	if not retained.contains("_draw_body_fallback(_body_texture_rect())"):
		_fail("Retained catalog cards should draw vector text overlay directly.")
	var prewarm_start := source.find("func _prewarm_adjacent_catalog_card_bodies")
	var prewarm_end := source.find("func mark_editor_dirty", prewarm_start)
	if prewarm_start < 0 or prewarm_end < 0:
		_fail("Adjacent card prewarm function missing.")
	var prewarm_block := source.substr(prewarm_start, prewarm_end - prewarm_start)
	if prewarm_block.contains("CatalogCardBodyTextureCache.prewarm"):
		_fail("Adjacent catalog preload should not bake card text into body textures.")
	print("CATALOG_CARD_TEXT_VECTOR_OVERLAY_PROBE ok")
	quit()
