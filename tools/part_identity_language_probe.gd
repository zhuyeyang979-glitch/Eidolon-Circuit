extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const PartCatalogCardButton := preload("res://scripts/views/catalog/part_catalog_card_button.gd")
const EditorPartHoverPopupView := preload("res://scripts/views/editor/editor_part_hover_popup_view.gd")
const BattlePartPreviewView := preload("res://scripts/views/battle_part_preview_view.gd")

const SCREENSHOT_PATH := "res://assets/concepts/parts/image2_individual/part_identity_language_v1.png"


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _save_screenshot() -> bool:
	var viewport_texture := root.get_viewport().get_texture()
	if viewport_texture == null:
		return false
	var image := viewport_texture.get_image()
	if image == null or image.is_empty():
		return false
	return image.save_png(SCREENSHOT_PATH) == OK


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("PART_IDENTITY_LANGUAGE_PROBE skipped headless")
		quit(0)
		return
	root.size = Vector2i(1280, 720)
	var main := MainScene.new()
	main.visible = false
	root.add_child(main)
	await process_frame
	main.loading_auto_transitions_enabled = false
	main.ui_language = "zh"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_part_group_mode = "terminal_weapon"
	main.editor_part_filter_mode = "weapon_all"
	main.editor_weapon_filter_group = "all"
	main.editor_weapon_filter_subtype = "all"
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	main._invalidate_editor_catalog_cache()
	var entries: Array = main._editor_catalog_entries("hero", "muscle")
	var models: Array = main._editor_catalog_page_models("hero", "muscle", main._editor_current_blueprint(), entries, 0, 8)
	if models.size() < 4:
		_fail("Could not build enough catalog models for identity probe.")
		return
	var board := Control.new()
	board.name = "PartIdentityLanguageProbe"
	board.size = Vector2(1280.0, 720.0)
	root.add_child(board)
	_draw_background(board)
	_add_label(board, "相似部件卡片：用编码 + 标签区分轮廓接近的配件", Vector2(42.0, 32.0), 18, Color(0.9, 0.98, 1.0, 1.0))
	_add_label(board, "悬浮详情：放大图仍保留同一套识别语言", Vector2(506.0, 32.0), 18, Color(0.9, 0.98, 1.0, 1.0))
	_add_label(board, "局中蓝图：疑似/未知时隐藏精确型号，只显示大类", Vector2(506.0, 474.0), 18, Color(0.9, 0.98, 1.0, 1.0))
	_add_catalog_cards(board, models)
	var selected_model: Dictionary = Dictionary(models[1])
	var selected_part: Dictionary = Dictionary(selected_model.get("part", {}))
	var hover_subtitle := main._hover_card_subtitle("muscle", selected_part)
	var hover_lines: Array = main._hover_card_player_detail_lines("muscle", selected_part)
	var hover_stats: Array = main._hover_card_stat_entries("muscle", selected_part)
	root.remove_child(main)
	main.queue_free()
	var hover := _add_hover_card(board, selected_model, selected_part, hover_subtitle, hover_lines, hover_stats)
	_add_battle_previews(board, selected_part)
	for frame in range(64):
		MainScene.PartPreviewTextureCache.process_queue(board, 8)
		for raw_child in board.get_children():
			if raw_child is PartCatalogCardButton:
				var card: PartCatalogCardButton = raw_child
				if card.retained_item != null:
					card.retained_item.refresh_preview_texture()
					card.retained_item.queue_redraw()
		_refresh_hover_preview_icon(hover)
		RenderingServer.force_draw()
		await process_frame
		if MainScene.PartPreviewTextureCache.pending_order.is_empty() and MainScene.PartPreviewTextureCache.active_request.is_empty():
			break
	for frame in range(4):
		RenderingServer.force_draw()
		await process_frame
	if not _save_screenshot():
		_fail("Could not save screenshot to %s" % SCREENSHOT_PATH)
		return
	print("PART_IDENTITY_LANGUAGE_SCREENSHOT %s" % SCREENSHOT_PATH)
	quit(0)


func _draw_background(parent: Control) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.006, 0.012, 0.018, 1.0)
	bg.size = parent.size
	parent.add_child(bg)
	for i in range(14):
		var line := ColorRect.new()
		line.color = Color(0.08, 0.24, 0.3, 0.22)
		line.position = Vector2(0.0, 78.0 + float(i) * 44.0)
		line.size = Vector2(parent.size.x, 1.0)
		parent.add_child(line)
	for i in range(13):
		var line := ColorRect.new()
		line.color = Color(0.08, 0.24, 0.3, 0.16)
		line.position = Vector2(38.0 + float(i) * 92.0, 0.0)
		line.size = Vector2(1.0, parent.size.y)
		parent.add_child(line)


func _add_catalog_cards(parent: Control, models: Array) -> void:
	var start := Vector2(42.0, 82.0)
	var card_size := Vector2(184.0, 92.0)
	for i in range(mini(models.size(), 8)):
		var model: Dictionary = Dictionary(models[i])
		var card := PartCatalogCardButton.new()
		card.position = start + Vector2(float(i % 2) * (card_size.x + 18.0), float(i / 2) * (card_size.y + 18.0))
		card.size = card_size
		card.disabled = true
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(card)
		card.set_card(
			String(model.get("slot", "muscle")),
			Dictionary(model.get("part", {})),
			i == 1,
			"zh",
			int(model.get("part_index", i)),
			String(model.get("title", "")),
			String(model.get("line_a", "")),
			String(model.get("line_b", ""))
		)


func _add_hover_card(parent: Control, model: Dictionary, part: Dictionary, subtitle: String, lines: Array, stat_entries: Array) -> EditorPartHoverPopupView:
	var hover := EditorPartHoverPopupView.new()
	hover.position = Vector2(506.0, 72.0)
	hover.size = Vector2(360.0, 376.0)
	parent.add_child(hover)
	hover.set_part(
		"muscle",
		part,
		String(model.get("title", "")),
		subtitle,
		lines,
		"zh",
		stat_entries,
		false,
		""
	)
	return hover


func _refresh_hover_preview_icon(hover: EditorPartHoverPopupView) -> void:
	if hover == null or hover.preview_icon == null:
		return
	var icon := hover.preview_icon
	if icon.slot_key == "" or icon.part.is_empty():
		return
	var texture := MainScene.PartPreviewTextureCache.peek_preview(icon.slot_key, icon.part, icon.selected, icon.pulse, icon.size)
	if texture != null and texture != icon.preview_texture:
		icon.preview_texture = texture
		icon.queue_redraw()


func _add_battle_previews(parent: Control, part: Dictionary) -> void:
	var partial := part.duplicate(true)
	partial["scan_level"] = 1
	var unknown := part.duplicate(true)
	unknown["scan_level"] = 0
	var partial_preview := BattlePartPreviewView.new()
	partial_preview.position = Vector2(506.0, 514.0)
	partial_preview.size = Vector2(320.0, 144.0)
	parent.add_child(partial_preview)
	partial_preview.set_component("muscle", partial, "zh")
	var unknown_preview := BattlePartPreviewView.new()
	unknown_preview.position = Vector2(850.0, 514.0)
	unknown_preview.size = Vector2(320.0, 144.0)
	parent.add_child(unknown_preview)
	unknown_preview.set_component("muscle", unknown, "zh")


func _add_label(parent: Control, text_value: String, pos: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.size = Vector2(420.0, 28.0)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
