extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var cache_block := FileAccess.get_file_as_string("res://scripts/views/catalog/part_preview_texture_cache.gd")
	if cache_block.is_empty() or cache_block.find("class_name PartPreviewTextureCache") < 0:
		_fail("PartPreviewTextureCache missing.")
		return
	if cache_block.contains("RenderingServer.force_draw"):
		_fail("Preview texture cache still forces a synchronous GPU draw.")
		return
	if not cache_block.contains("_submit_render") or not cache_block.contains("_capture_active_request"):
		_fail("Preview texture cache is not split into submit/capture async stages.")
		return
	print("PART_PREVIEW_NO_FORCE_DRAW_PROBE ok")
	quit(0)
