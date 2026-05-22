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
	var before_viewports := int(MainScene.PartPreviewTextureCache.subviewport_create_count)
	var before_render := int(MainScene.PartPreviewTextureCache.render_count)
	var processed := MainScene.PartPreviewTextureCache.process_queue(main, 4)
	if DisplayServer.get_name().to_lower() != "headless":
		if processed <= 0:
			_fail("Headed preview queue did not process any pending texture.")
			return
		if int(MainScene.PartPreviewTextureCache.render_count) <= before_render:
			_fail("Headed preview queue did not render any texture. processed=%d display=%s inside=%s viewports=%d renders=%d" % [
				processed,
				DisplayServer.get_name(),
				str(main.is_inside_tree()),
				int(MainScene.PartPreviewTextureCache.subviewport_create_count),
				int(MainScene.PartPreviewTextureCache.render_count),
			])
			return
		var created := int(MainScene.PartPreviewTextureCache.subviewport_create_count) - before_viewports
		if created > 1:
			_fail("Preview cache created more than one SubViewport for one queue batch: %d." % created)
			return
	print("PART_PREVIEW_QUEUE_RENDER_PROBE ok processed=%d viewports=%d renders=%d" % [
		processed,
		int(MainScene.PartPreviewTextureCache.subviewport_create_count),
		int(MainScene.PartPreviewTextureCache.render_count),
	])
	quit(0)
