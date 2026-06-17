extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const PartCatalogCardButton := preload("res://scripts/views/catalog/part_catalog_card_button.gd")

const REPORT_PATH := "res://assets/concepts/parts/image2_individual/unit_editor_catalog_asset_coverage_report_v1.json"
const SCREENSHOT_PATH := "res://assets/concepts/parts/image2_individual/unit_editor_catalog_asset_coverage_panel_v1.png"
const PREVIEW_SIZE := Vector2(114.0, 28.0)
const TARGET_COUNT := 103


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("CATALOG_ASSET_COVERAGE_PROBE skipped headless")
		quit(0)
		return
	root.size = Vector2i(1280, 720)
	var main := MainScene.new()
	root.add_child(main)
	await process_frame
	main.loading_auto_transitions_enabled = false
	main._show_editor(true)
	main.editor_panel_mode = "parts"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.ui_language = "zh"
	await process_frame

	var current_state := _panel_state(main, "current_after_show")
	var terminal_state := _apply_panel_state(main, "terminal_weapon_all", "hero", "terminal_weapon", "weapon_all", "muscle", "all", "all")
	var legacy_terminal_state := _apply_panel_state(main, "legacy_terminal_filter", "hero", "muscle", "terminal", "muscle", "all", "all")
	var matching_states := _scan_matching_panel_states(main, "hero", TARGET_COUNT)

	var target_state: Dictionary = {}
	if int(current_state.get("entry_count", 0)) == TARGET_COUNT:
		target_state = current_state
	elif int(terminal_state.get("entry_count", 0)) == TARGET_COUNT:
		target_state = terminal_state
	elif int(legacy_terminal_state.get("entry_count", 0)) == TARGET_COUNT:
		target_state = legacy_terminal_state
	elif not matching_states.is_empty():
		target_state = Dictionary(matching_states[0])
	else:
		target_state = terminal_state

	_apply_state_from_summary(main, target_state)
	main.editor_catalog_page = 0
	main._invalidate_editor_catalog_cache()
	main._update_editor_ui(true)
	await process_frame

	var coverage := await _coverage_for_current_panel(main)
	_refresh_visible_catalog_previews(main)
	for frame in range(3):
		RenderingServer.force_draw()
		await process_frame
	var screenshot_ok := _save_screenshot()
	var report := {
		"target_count_requested": TARGET_COUNT,
		"current_after_show": current_state,
		"terminal_weapon_all": terminal_state,
		"legacy_terminal_filter": legacy_terminal_state,
		"matching_103_states": matching_states,
		"tested_panel": _panel_state(main, "tested_panel"),
		"coverage": coverage,
		"screenshot_path": SCREENSHOT_PATH if screenshot_ok else "",
	}
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		_fail("Could not write report to %s" % REPORT_PATH)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("CATALOG_ASSET_COVERAGE_REPORT %s" % REPORT_PATH)
	print("CATALOG_ASSET_COVERAGE_SCREENSHOT %s" % SCREENSHOT_PATH)
	print("CURRENT_ENTRY_COUNT %d" % int(current_state.get("entry_count", 0)))
	print("TERMINAL_ENTRY_COUNT %d" % int(terminal_state.get("entry_count", 0)))
	print("LEGACY_TERMINAL_ENTRY_COUNT %d" % int(legacy_terminal_state.get("entry_count", 0)))
	print("MATCHING_103_STATES %d" % matching_states.size())
	print("TESTED_ENTRY_COUNT %d" % int(report.get("tested_panel", {}).get("entry_count", 0)))
	print("TEXT_OK %d/%d" % [int(coverage.get("text_ok", 0)), int(coverage.get("entry_count", 0))])
	print("PREVIEW_OK %d/%d" % [int(coverage.get("preview_ok", 0)), int(coverage.get("entry_count", 0))])
	print("MISSING_TEXT %d" % Array(coverage.get("missing_text", [])).size())
	print("MISSING_PREVIEW %d" % Array(coverage.get("missing_preview", [])).size())
	quit(0)


func _panel_state(main: Node, label: String) -> Dictionary:
	var role_key := String(MainScene.ROLE_ORDER[main.editor_role_index])
	var slot_key := String(MainScene.BUILD_SLOTS[main.editor_slot_index])
	var entries: Array = main._editor_catalog_entries(role_key, slot_key)
	var page_size := maxi(1, main.editor_catalog_buttons.size())
	var max_page := maxi(0, int(ceilf(float(entries.size()) / float(page_size))) - 1)
	return {
		"label": label,
		"role": role_key,
		"slot": slot_key,
		"part_group_mode": String(main.editor_part_group_mode),
		"part_filter_mode": String(main.editor_part_filter_mode),
		"weapon_filter_group": String(main.editor_weapon_filter_group),
		"weapon_filter_subtype": String(main.editor_weapon_filter_subtype),
		"sort_key": String(main.editor_catalog_sort_key),
		"sort_ascending": bool(main.editor_catalog_sort_ascending),
		"entry_count": entries.size(),
		"page_size": page_size,
		"max_page": max_page,
	}


func _apply_panel_state(main: Node, label: String, role_key: String, group_key: String, filter_key: String, slot_key: String, weapon_group: String = "all", weapon_subtype: String = "all") -> Dictionary:
	main.editor_role_index = MainScene.ROLE_ORDER.find(role_key)
	if main.editor_role_index < 0:
		main.editor_role_index = 0
	main.editor_slot_index = MainScene.BUILD_SLOTS.find(slot_key)
	if main.editor_slot_index < 0:
		main.editor_slot_index = 0
	main.editor_part_group_mode = group_key
	main.editor_part_filter_mode = filter_key
	main.editor_weapon_filter_group = weapon_group
	main.editor_weapon_filter_subtype = weapon_subtype
	main.editor_catalog_page = 0
	main._invalidate_editor_catalog_cache()
	return _panel_state(main, label)


func _apply_state_from_summary(main: Node, state: Dictionary) -> void:
	main.editor_role_index = MainScene.ROLE_ORDER.find(String(state.get("role", "hero")))
	if main.editor_role_index < 0:
		main.editor_role_index = 0
	main.editor_slot_index = MainScene.BUILD_SLOTS.find(String(state.get("slot", "muscle")))
	if main.editor_slot_index < 0:
		main.editor_slot_index = 0
	main.editor_part_group_mode = String(state.get("part_group_mode", "terminal_weapon"))
	main.editor_part_filter_mode = String(state.get("part_filter_mode", "weapon_all"))
	main.editor_weapon_filter_group = String(state.get("weapon_filter_group", "all"))
	main.editor_weapon_filter_subtype = String(state.get("weapon_filter_subtype", "all"))


func _scan_matching_panel_states(main: Node, role_key: String, target_count: int) -> Array:
	var results: Array = []
	var groups := ["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"]
	for group_key in groups:
		var state: Dictionary = main.unit_editor_catalog_controller.state_for_part_group_selection(group_key, role_key, String(MainScene.BUILD_SLOTS[main.editor_slot_index]), MainScene.BUILD_SLOTS, "all")
		if not bool(state.get("valid", false)):
			continue
		var options: Array = main.unit_editor_catalog_controller.filter_options_for_group(group_key, "all", true)
		for raw_option in options:
			if not (raw_option is Dictionary):
				continue
			var option: Dictionary = raw_option
			var filter_key := String(option.get("key", "all"))
			var option_state: Dictionary = main.unit_editor_catalog_controller.state_for_filter_selection(options.find(raw_option), group_key, String(MainScene.BUILD_SLOTS[main.editor_slot_index]), MainScene.BUILD_SLOTS, "all")
			var slot_index := int(option_state.get("slot_index", state.get("slot_index", 0)))
			slot_index = clampi(slot_index, 0, MainScene.BUILD_SLOTS.size() - 1)
			var slot_key := String(MainScene.BUILD_SLOTS[slot_index])
			var weapon_group := String(option.get("weapon_group", "all")) if group_key == "terminal_weapon" else "all"
			var weapon_subtype := String(option.get("weapon_subtype", "all")) if group_key == "terminal_weapon" else "all"
			var summary := _apply_panel_state(main, "%s:%s" % [group_key, filter_key], role_key, group_key, filter_key, slot_key, weapon_group, weapon_subtype)
			if int(summary.get("entry_count", 0)) == target_count:
				results.append(summary)
	return results


func _coverage_for_current_panel(main: Node) -> Dictionary:
	var role_key := String(MainScene.ROLE_ORDER[main.editor_role_index])
	var slot_key := String(MainScene.BUILD_SLOTS[main.editor_slot_index])
	var entries: Array = main._editor_catalog_entries(role_key, slot_key)
	var models: Array = []
	if not entries.is_empty():
		models = main._editor_catalog_page_models(role_key, slot_key, main._editor_current_blueprint(), entries, 0, entries.size())
	var missing_text: Array = []
	var missing_preview: Array = []
	var preview_requests: Array = []
	for i in range(models.size()):
		var model: Dictionary = Dictionary(models[i])
		var entry_slot := String(model.get("slot", slot_key))
		var part_index := int(model.get("part_index", -1))
		var part: Dictionary = Dictionary(model.get("part", {}))
		var title := String(model.get("title", ""))
		var line_a := String(model.get("line_a", ""))
		var line_b := String(model.get("line_b", ""))
		var item := {
			"absolute_index": i,
			"slot": entry_slot,
			"part_index": part_index,
			"name": String(part.get("name", "")),
			"title": title,
			"line_a": line_a,
			"line_b": line_b,
		}
		if title.strip_edges() == "" or line_a.strip_edges() == "" or line_b.strip_edges() == "":
			missing_text.append(item)
		MainScene.PartPreviewTextureCache.request_preview(main, entry_slot, part, false, 0.0, PREVIEW_SIZE)
		preview_requests.append({
			"slot": entry_slot,
			"part": part,
			"item": item,
		})
	for frame in range(maxi(24, preview_requests.size() * 3)):
		MainScene.PartPreviewTextureCache.process_queue(main, 8)
		RenderingServer.force_draw()
		await process_frame
		if MainScene.PartPreviewTextureCache.pending_order.is_empty() and MainScene.PartPreviewTextureCache.active_request.is_empty():
			break
	for request in preview_requests:
		var preview := MainScene.PartPreviewTextureCache.peek_preview(String(request.get("slot", "")), Dictionary(request.get("part", {})), false, 0.0, PREVIEW_SIZE)
		if preview == null:
			missing_preview.append(Dictionary(request.get("item", {})))
	var entry_count := models.size()
	return {
		"entry_count": entry_count,
		"text_ok": entry_count - missing_text.size(),
		"preview_ok": entry_count - missing_preview.size(),
		"missing_text": missing_text,
		"missing_preview": missing_preview,
		"preview_cache_size": MainScene.PartPreviewTextureCache.textures.size(),
		"preview_submit_count": MainScene.PartPreviewTextureCache.submit_count,
		"preview_capture_count": MainScene.PartPreviewTextureCache.capture_count,
	}


func _refresh_visible_catalog_previews(main: Node) -> void:
	for raw_button in main.editor_catalog_buttons:
		if raw_button == null or not (raw_button is PartCatalogCardButton):
			continue
		var button: PartCatalogCardButton = raw_button
		if button.retained_item != null:
			button.retained_item.refresh_preview_texture()
			button.retained_item.queue_redraw()
		button.queue_redraw()


func _save_screenshot() -> bool:
	var viewport_texture := root.get_viewport().get_texture()
	if viewport_texture == null:
		return false
	var image := viewport_texture.get_image()
	if image == null or image.is_empty():
		return false
	return image.save_png(SCREENSHOT_PATH) == OK
