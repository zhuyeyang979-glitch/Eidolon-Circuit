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
	if not main_source.contains("class PartPreviewTextureCache"):
		failures.append("PartPreviewTextureCache missing")
	if not main_source.contains("request_preview") or not main_source.contains("process_queue"):
		failures.append("PartPreviewTextureCache is not request/queue based")
	if not main_source.contains("class PartPreviewTextureRenderCanvas"):
		failures.append("Preview render canvas missing")
	if not main_source.contains("class PartPreviewIconView"):
		failures.append("PartPreviewIconView missing")
	var icon_pos := main_source.find("class PartPreviewIconView")
	if icon_pos >= 0:
		var icon_block := main_source.substr(icon_pos, min(1600, main_source.length() - icon_pos))
		var draw_pos := icon_block.find("func _draw() -> void:")
		var draw_block := icon_block.substr(draw_pos, min(500, icon_block.length() - draw_pos)) if draw_pos >= 0 else ""
		if draw_block.contains("AssemblyBoardRenderer.draw_part_preview"):
			failures.append("PartPreviewIconView._draw still calls full renderer instead of cached texture")
		if draw_block.contains("SubViewport.new") or draw_block.contains("RenderingServer.force_draw"):
			failures.append("PartPreviewIconView._draw still creates/renders SubViewport")
	var canvas_pos := main_source.find("class PartPreviewTextureRenderCanvas")
	if canvas_pos >= 0:
		var canvas_block := main_source.substr(canvas_pos, min(600, main_source.length() - canvas_pos))
		if not canvas_block.contains("AssemblyBoardRenderer.draw_part_preview"):
			failures.append("Offscreen preview canvas is not renderer-driven")
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
