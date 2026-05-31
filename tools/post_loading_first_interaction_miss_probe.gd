extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._begin_post_loading_interaction_window("probe")
	var before := int(main.post_loading_miss_count)
	MainScene.PartPreviewTextureCache.miss_count += 1
	main._sample_post_loading_misses("probe:first_interaction")
	if int(main.post_loading_miss_count) <= before:
		_fail("Post-loading miss sampler did not record preview miss.")
		return
	if main.post_loading_miss_log.is_empty():
		_fail("Post-loading miss log remained empty.")
		return
	print("POST_LOADING_FIRST_INTERACTION_MISS_PROBE ok misses=%d last=%s" % [
		int(main.post_loading_miss_count),
		str(main.post_loading_miss_log.back()),
	])
	quit(0)
