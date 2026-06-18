extends SceneTree


const CACHE_PATH := "res://scripts/views/catalog/part_preview_texture_cache.gd"
const ICON_PATH := "res://scripts/views/catalog/part_preview_icon_view.gd"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _class_block(source: String, klass: String) -> String:
	var start := source.find("class_name %s" % klass)
	if start < 0:
		start = source.find("class %s" % klass)
	return "" if start < 0 else source.substr(start)


func _draw_block(class_source: String) -> String:
	var start := class_source.find("func _draw() -> void:")
	if start < 0:
		return ""
	var next := class_source.find("\nfunc ", start + 1)
	if next < 0:
		next = class_source.length()
	return class_source.substr(start, next - start)


func _init() -> void:
	var cache_source := FileAccess.get_file_as_string(CACHE_PATH)
	var icon_source := FileAccess.get_file_as_string(ICON_PATH)
	if cache_source.is_empty() or icon_source.is_empty():
		_fail("Unable to read extracted part preview sources.")
	var cache_block := _class_block(cache_source, "PartPreviewTextureCache")
	if cache_block.is_empty():
		_fail("PartPreviewTextureCache missing.")
	if not cache_block.contains("request_preview"):
		_fail("PartPreviewTextureCache does not expose request_preview.")
	if not cache_block.contains("process_queue"):
		_fail("PartPreviewTextureCache does not expose process_queue.")
	if not cache_block.contains("render_viewport"):
		_fail("PartPreviewTextureCache does not use a persistent render viewport.")
	var icon_block := _class_block(icon_source, "PartPreviewIconView")
	var icon_draw := _draw_block(icon_block)
	if icon_draw.contains("SubViewport.new") or icon_draw.contains("RenderingServer.force_draw") or icon_draw.contains("AssemblyBoardRenderer.draw_part_preview"):
		_fail("PartPreviewIconView._draw still performs heavyweight preview rendering.")
	print("PART_PREVIEW_NO_SUBVIEWPORT_PER_DRAW_PROBE ok")
	quit(0)
