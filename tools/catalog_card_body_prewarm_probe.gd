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
	main.editor_catalog_page = 0
	main._update_editor_ui(true)
	var page_size: int = max(1, main.editor_catalog_buttons.size())
	var chosen_slot := -1
	for i in range(MainScene.BUILD_SLOTS.size()):
		main.editor_slot_index = i
		var slot_key := String(MainScene.BUILD_SLOTS[i])
		var entries: Array = main._editor_catalog_entries(String(MainScene.ROLE_ORDER[main.editor_role_index]), slot_key)
		if entries.size() > page_size:
			chosen_slot = i
			break
	if chosen_slot < 0:
		_fail("No catalog slot has an adjacent page to prewarm.")
		return
	main.editor_slot_index = chosen_slot
	main.editor_catalog_page = 0
	main._update_editor_ui(true)
	main.editor_preview_pause_until_msec = 0
	var text := main._editor_perf_overlay_text()
	for required in ["card body h/m/q/a", "card body sub/cap/prewarm", "card body time req/sub/cap"]:
		if not text.contains(required):
			_fail("Perf overlay missing card body field: %s" % required)
			return
	if DisplayServer.get_name().to_lower() == "headless":
		main._tick_editor_visuals(1.0 / 60.0)
		if int(MainScene.CatalogCardBodyTextureCache.prewarm_request_count) != 0:
			_fail("Headless should not queue card body prewarm requests.")
		print("CATALOG_CARD_BODY_PREWARM_PROBE headless-skip")
		quit(0)
		return
	var prewarm_before := int(MainScene.CatalogCardBodyTextureCache.prewarm_request_count)
	for i in range(48):
		main._tick_editor_visuals(1.0 / 60.0)
		await process_frame
		main.editor_preview_pause_until_msec = 0
		if int(MainScene.CatalogCardBodyTextureCache.prewarm_request_count) > prewarm_before and int(MainScene.CatalogCardBodyTextureCache.capture_count) > 0:
			break
	var prewarm_after := int(MainScene.CatalogCardBodyTextureCache.prewarm_request_count)
	if prewarm_after <= prewarm_before:
		var role_key := String(MainScene.ROLE_ORDER[main.editor_role_index])
		var slot_key := String(MainScene.BUILD_SLOTS[main.editor_slot_index])
		var entries: Array = main._editor_catalog_entries(role_key, slot_key)
		_fail("Adjacent catalog card body prewarm did not queue any requests. slot=%s entries=%d page_size=%d active=%d pending=%d pause=%d display=%s" % [
			slot_key,
			entries.size(),
			page_size,
			MainScene.CatalogCardBodyTextureCache.active_request.size(),
			MainScene.CatalogCardBodyTextureCache.pending_order.size(),
			int(main.editor_preview_pause_until_msec) - int(Time.get_ticks_msec()),
			DisplayServer.get_name(),
		])
		return
	var processed := int(MainScene.CatalogCardBodyTextureCache.submit_count) + int(MainScene.CatalogCardBodyTextureCache.capture_count)
	if processed <= 0:
		_fail("Card body cache did not submit or capture headed work.")
		return
	print("CATALOG_CARD_BODY_PREWARM_PROBE ok prewarm=%d submit=%d capture=%d last=%.2f/%.2f/%.2fms" % [
		prewarm_after - prewarm_before,
		int(MainScene.CatalogCardBodyTextureCache.submit_count),
		int(MainScene.CatalogCardBodyTextureCache.capture_count),
		float(MainScene.CatalogCardBodyTextureCache.last_request_usec) / 1000.0,
		float(MainScene.CatalogCardBodyTextureCache.last_submit_usec) / 1000.0,
		float(MainScene.CatalogCardBodyTextureCache.last_capture_usec) / 1000.0,
	])
	quit(0)
