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
	main._update_editor_ui(true)
	if main.hot_path_profiler == null:
		_fail("HotPathProfiler missing.")
		return
	main.hot_path_profiler.begin_interaction("catalog.scroll")
	var before_card_updates := int(main.editor_catalog_card_update_count)
	var before_preview_submit := int(MainScene.PartPreviewTextureCache.submit_count)
	var page_changes := 36
	for i in range(page_changes):
		main.hot_path_profiler.begin_frame()
		main.editor_catalog_page = i % 4
		main.mark_editor_dirty(MainScene.EDITOR_DIRTY_CATALOG, "probe_scroll")
		main.flush_editor_dirty(2400)
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("catalog.scroll")
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("catalog.scroll")
	if int(stats.get("count", 0)) <= 0:
		_fail("Catalog scroll interaction samples missing.")
		return
	var card_updates := int(main.editor_catalog_card_update_count) - before_card_updates
	var preview_submits := int(MainScene.PartPreviewTextureCache.submit_count) - before_preview_submit
	var visible_card_budget: int = max(1, main.editor_catalog_buttons.size()) * page_changes
	if card_updates > visible_card_budget:
		_fail("Catalog scroll updated too many card batches: %d" % card_updates)
		return
	var before_same_page_updates := int(main.editor_catalog_card_update_count)
	for i in range(12):
		main.hot_path_profiler.begin_frame()
		main.mark_editor_dirty(MainScene.EDITOR_DIRTY_CATALOG, "probe_same_page")
		main.flush_editor_dirty(2400)
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	var same_page_updates := int(main.editor_catalog_card_update_count) - before_same_page_updates
	if same_page_updates > 0:
		_fail("Catalog same-page dirty flush rewrote unchanged cards: %d" % same_page_updates)
		return
	var leaf_text := _leaf_scope_text(main.hot_path_profiler, "catalog.scroll")
	print("TEAMEDIT_SCROLL_FRAME_BUDGET_PROBE ok p95=%.2fms max=%.2fms card_updates=%d same_page_updates=%d preview_submit=%d hot=%s leaf=%s" % [
		float(stats.get("p95_usec", 0)) / 1000.0,
		float(stats.get("max_usec", 0)) / 1000.0,
		card_updates,
		same_page_updates,
		preview_submits,
		String(stats.get("hot_scope", "")),
		leaf_text,
	])
	quit(0)


func _leaf_scope_text(profiler, interaction_name: String) -> String:
	if profiler == null or not profiler.has_method("interaction_hot_scopes"):
		return "n/a"
	var rows: Array = profiler.interaction_hot_scopes(interaction_name, 4, true)
	var parts: Array = []
	for row in rows:
		var scope_name := String(row.get("name", ""))
		if scope_name in ["teamedit.flush_dirty", "teamedit.flush.catalog"]:
			continue
		parts.append("%s:%.2fms" % [scope_name, float(row.get("usec", 0)) / 1000.0])
	var text := ""
	for i in range(parts.size()):
		if i > 0:
			text += ","
		text += String(parts[i])
	return text
