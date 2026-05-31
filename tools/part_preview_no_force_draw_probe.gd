extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var cache_start := source.find("class PartPreviewTextureCache:")
	if cache_start < 0:
		_fail("PartPreviewTextureCache missing.")
		return
	var next_class := source.find("\nclass PartPreviewIconView:", cache_start)
	if next_class < 0:
		next_class = source.length()
	var cache_block := source.substr(cache_start, next_class - cache_start)
	if cache_block.contains("RenderingServer.force_draw"):
		_fail("Preview texture cache still forces a synchronous GPU draw.")
		return
	if not cache_block.contains("_submit_render") or not cache_block.contains("_capture_active_request"):
		_fail("Preview texture cache is not split into submit/capture async stages.")
		return
	print("PART_PREVIEW_NO_FORCE_DRAW_PROBE ok")
	quit(0)
