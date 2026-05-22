extends SceneTree


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var renderer_source := FileAccess.get_file_as_string("res://scripts/assembly_board_renderer.gd")
	if main_source.is_empty() or renderer_source.is_empty():
		push_error("Unable to read main.gd or assembly_board_renderer.gd")
		quit(1)
		return
	var failures: Array[String] = []
	if not renderer_source.contains("static func draw_part_preview"):
		failures.append("AssemblyBoardRenderer.draw_part_preview missing")
	if not renderer_source.contains("static func part_to_component_node"):
		failures.append("AssemblyBoardRenderer.part_to_component_node missing")
	var draw_art_pos := main_source.find("func _draw_art(rect: Rect2)")
	if draw_art_pos < 0:
		failures.append("PartCatalogCardButton._draw_art missing")
	else:
		var draw_art_block := main_source.substr(draw_art_pos, min(900, main_source.length() - draw_art_pos))
		if not draw_art_block.contains("AssemblyBoardRenderer.draw_part_preview"):
			failures.append("PartCatalogCardButton._draw_art does not call AssemblyBoardRenderer.draw_part_preview")
		if draw_art_block.contains("_draw_shared_card_asset"):
			failures.append("PartCatalogCardButton._draw_art still calls old shared asset thumbnail path")
	var hover_pos := main_source.find("func _draw_large_art(rect: Rect2)")
	if hover_pos < 0:
		failures.append("EditorPartHoverPopupView._draw_large_art missing")
	else:
		var hover_block := main_source.substr(hover_pos, min(500, main_source.length() - hover_pos))
		if not hover_block.contains("AssemblyBoardRenderer.draw_part_preview"):
			failures.append("EditorPartHoverPopupView._draw_large_art does not call AssemblyBoardRenderer.draw_part_preview")
	if not main_source.contains("class PartDragGhostView") or not main_source.contains("extends PartCatalogCardButton"):
		failures.append("PartDragGhostView no longer inherits catalog card renderer")
	if main_source.contains("func set_art_sheets") and not main_source.contains("Thumbnail art is now renderer-driven"):
		failures.append("set_art_sheets is not marked as renderer-driven compatibility")
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("PART_CATALOG_THUMBNAIL_RENDERER_PROBE ok")
	quit(0)
