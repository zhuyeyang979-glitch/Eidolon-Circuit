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
	var button: Button = null
	for raw_button in main.editor_catalog_buttons:
		if raw_button is Button and raw_button.visible and not raw_button.disabled:
			button = raw_button
			break
	if button == null:
		_fail("No visible catalog button for click probe.")
		return
	main.hot_path_profiler.begin_interaction("teamedit.click")
	var before_updates := int(main.editor_catalog_card_update_count)
	for i in range(5):
		main.hot_path_profiler.begin_frame()
		main.ui_mouse_click_latch_msec = 0
		main._trigger_button_mouse_fallback(button)
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.click")
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("teamedit.click")
	var catalog_updates := int(main.editor_catalog_card_update_count) - before_updates
	if int(stats.get("count", 0)) <= 0:
		_fail("Click profiler samples missing.")
		return
	if catalog_updates > main.editor_catalog_buttons.size() * 2:
		_fail("Catalog click caused excessive card rewrites: %d" % catalog_updates)
		return
	print("TEAMEDIT_CLICK_FRAME_BUDGET_PROBE ok p95=%.2fms max=%.2fms updates=%d hot=%s" % [
		float(stats.get("p95_usec", 0.0)) / 1000.0,
		float(stats.get("max_usec", 0.0)) / 1000.0,
		catalog_updates,
		String(stats.get("hot_scope", "")),
	])
	quit(0)
