extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var board_start := source.find("func _update_editor_board_ui")
	var board_end := source.find("func _shop_slot_button_text", board_start)
	var block := source.substr(board_start, max(0, board_end - board_start))
	if not block.contains("catalog_domain_key") or not block.contains("editor_catalog_domain_revision_key"):
		_fail("Board UI does not gate catalog refresh behind a catalog domain revision.")
		return
	if not block.contains("visual_domain_key") or not block.contains("editor_board_visual_domain_revision_key"):
		_fail("Board UI does not gate visual refresh behind a visual domain revision.")
		return
	if block.contains("_update_editor_catalog_buttons(role_key, unit_bp)\n\t_refresh_editor_visual_views"):
		_fail("Board UI still chains catalog and visual refresh unconditionally.")
		return
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main._update_editor_ui(true)
	var catalog_before := int(main.editor_catalog_card_update_count)
	var visual_before := int(main.editor_visual_refresh_count)
	main.editor_board_hint_label.text = "probe"
	main._update_editor_board_ui(String(MainScene.ROLE_ORDER[main.editor_role_index]), main._editor_current_blueprint(), main._editor_current_stats())
	var catalog_after := int(main.editor_catalog_card_update_count)
	var visual_after := int(main.editor_visual_refresh_count)
	if catalog_after != catalog_before:
		_fail("Hint-only board UI pass refreshed catalog cards.")
		return
	if visual_after != visual_before:
		_fail("Hint-only board UI pass refreshed board visual snapshot.")
		return
	print("EDITOR_BOARD_UI_DOMAIN_DIRTY_PROBE ok catalog=%d visual=%d" % [catalog_after, visual_after])
	quit(0)
