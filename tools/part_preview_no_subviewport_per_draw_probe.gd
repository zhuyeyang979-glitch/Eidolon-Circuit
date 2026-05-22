extends SceneTree


const MAIN_PATH := "res://scripts/main.gd"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _class_block(source: String, klass: String) -> String:
	var start := source.find("class %s" % klass)
	if start < 0:
		return ""
	var next := source.find("\nclass ", start + 1)
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _draw_block(class_source: String) -> String:
	var start := class_source.find("func _draw() -> void:")
	if start < 0:
		return ""
	var next := class_source.find("\n\tfunc ", start + 1)
	if next < 0:
		next = class_source.length()
	return class_source.substr(start, next - start)


func _init() -> void:
	var source := FileAccess.get_file_as_string(MAIN_PATH)
	if source.is_empty():
		_fail("Unable to read main.gd.")
	var cache_block := _class_block(source, "PartPreviewTextureCache")
	if cache_block.is_empty():
		_fail("PartPreviewTextureCache missing.")
	if not cache_block.contains("request_preview"):
		_fail("PartPreviewTextureCache does not expose request_preview.")
	if not cache_block.contains("process_queue"):
		_fail("PartPreviewTextureCache does not expose process_queue.")
	if not cache_block.contains("render_viewport"):
		_fail("PartPreviewTextureCache does not use a persistent render viewport.")
	var icon_block := _class_block(source, "PartPreviewIconView")
	var icon_draw := _draw_block(icon_block)
	if icon_draw.contains("SubViewport.new") or icon_draw.contains("RenderingServer.force_draw") or icon_draw.contains("AssemblyBoardRenderer.draw_part_preview"):
		_fail("PartPreviewIconView._draw still performs heavyweight preview rendering.")
	print("PART_PREVIEW_NO_SUBVIEWPORT_PER_DRAW_PROBE ok")
	quit(0)
