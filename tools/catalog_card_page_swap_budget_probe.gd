extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_panel_mode = "parts"
	main._update_editor_ui(true)
	main.hot_path_profiler.begin_interaction("catalog.page_swap")
	var before_updates := int(main.editor_catalog_card_update_count)
	var before_preview_submit := int(MainScene.PartPreviewTextureCache.submit_count)
	var before_body_submit := int(MainScene.CatalogCardBodyTextureCache.submit_count)
	var page_size: int = max(1, main.editor_catalog_buttons.size())
	for warm_i in range(4):
		main.editor_catalog_page = warm_i % 4
		main.mark_editor_dirty(MainScene.EDITOR_DIRTY_CATALOG, "page_swap_warmup")
		main.flush_editor_dirty(2400)
		main._tick_editor_visuals(1.0 / 60.0)
	before_updates = int(main.editor_catalog_card_update_count)
	before_preview_submit = int(MainScene.PartPreviewTextureCache.submit_count)
	before_body_submit = int(MainScene.CatalogCardBodyTextureCache.submit_count)
	for i in range(16):
		main.hot_path_profiler.begin_frame()
		main.editor_preview_pause_until_msec = Time.get_ticks_msec() + 150
		main.editor_catalog_page = i % 4
		main.mark_editor_dirty(MainScene.EDITOR_DIRTY_CATALOG, "page_swap_probe")
		main.flush_editor_dirty(2400)
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("catalog.page_swap")
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("catalog.page_swap")
	var leaves: Array = main.hot_path_profiler.interaction_hot_scopes("catalog.page_swap", 4, true)
	var leaf_texts: Array = []
	for leaf in leaves:
		if leaf is Dictionary:
			leaf_texts.append("%s:%.2fms" % [String(Dictionary(leaf).get("name", "")), float(Dictionary(leaf).get("usec", 0)) / 1000.0])
	var updates := int(main.editor_catalog_card_update_count) - before_updates
	var preview_submit := int(MainScene.PartPreviewTextureCache.submit_count) - before_preview_submit
	var body_submit := int(MainScene.CatalogCardBodyTextureCache.submit_count) - before_body_submit
	if updates > page_size * 16:
		_fail("Page swap rewrote more card batches than visible pool: %d > %d" % [updates, page_size * 16])
		return
	if preview_submit > page_size:
		_fail("Page swap submitted too many part preview textures in headless logic path: %d" % preview_submit)
		return
	var p95_ms := float(stats.get("p95_usec", 0.0)) / 1000.0
	var p95_limit := 120.0 if DisplayServer.get_name().to_lower() == "headless" else 90.0
	if p95_ms > p95_limit:
		_fail("Page swap p95 too high: %.2fms hot=%s leaf=%s" % [float(stats.get("p95_usec", 0.0)) / 1000.0, String(stats.get("hot_scope", "")), ",".join(leaf_texts)])
		return
	print("CATALOG_CARD_PAGE_SWAP_BUDGET_PROBE ok p95=%.2fms updates=%d body_submit=%d hot=%s leaf=%s" % [
		float(stats.get("p95_usec", 0.0)) / 1000.0,
		updates,
		body_submit,
		String(stats.get("hot_scope", "")),
		",".join(leaf_texts),
	])
	quit(0)
