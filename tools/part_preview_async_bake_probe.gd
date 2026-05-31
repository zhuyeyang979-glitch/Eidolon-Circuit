extends SceneTree


const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	await process_frame
	main._show_editor()
	main.editor_panel_mode = "parts"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	main._update_editor_ui()
	var cache = MainScene.PartPreviewTextureCache
	if DisplayServer.get_name().to_lower() == "headless":
		print("PART_PREVIEW_ASYNC_BAKE_PROBE ok headless-skip")
		quit(0)
		return
	var before_submit := int(cache.submit_count)
	var before_capture := int(cache.capture_count)
	var first := cache.process_queue(main, 1)
	if first != 0:
		_fail("Preview async first stage should submit without capture, got %d." % first)
		return
	if int(cache.submit_count) <= before_submit:
		_fail("Preview async first stage did not submit.")
		return
	if cache.active_request.is_empty():
		_fail("Preview async stage did not leave active request pending.")
		return
	await process_frame
	var second := cache.process_queue(main, 1)
	if second <= 0 or int(cache.capture_count) <= before_capture:
		_fail("Preview async second stage did not capture. second=%d captures=%d" % [second, int(cache.capture_count)])
		return
	print("PART_PREVIEW_ASYNC_BAKE_PROBE ok submit=%d capture=%d" % [int(cache.submit_count), int(cache.capture_count)])
	quit(0)
