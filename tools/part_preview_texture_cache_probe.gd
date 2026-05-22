extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _preview_apply_total(main) -> int:
	var total := 0
	for button in main.editor_catalog_buttons:
		if button != null and button.preview_icon != null:
			total += int(button.preview_icon.set_preview_apply_count)
	return total


func _preview_noop_total(main) -> int:
	var total := 0
	for button in main.editor_catalog_buttons:
		if button != null and button.preview_icon != null:
			total += int(button.preview_icon.set_preview_noop_count)
	return total


func _preview_draw_total(main) -> int:
	var total := 0
	for button in main.editor_catalog_buttons:
		if button != null and button.preview_icon != null:
			total += int(button.preview_icon.renderer_draw_count)
	return total


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_panel_mode = "parts"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	main.editor_part_group_mode = "terminal_weapon"
	main.editor_part_filter_mode = "terminal_melee"
	main._update_editor_ui()
	var role_key := "hero"
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._update_editor_catalog_buttons(role_key, unit_bp)
	var apply_before := _preview_apply_total(main)
	var noop_before := _preview_noop_total(main)
	var draw_before := _preview_draw_total(main)
	main._update_editor_catalog_buttons(role_key, unit_bp)
	var apply_after := _preview_apply_total(main)
	var noop_after := _preview_noop_total(main)
	var draw_after := _preview_draw_total(main)
	if apply_after != apply_before:
		_fail("Repeated catalog refresh reapplied preview renderer cache: before=%d after=%d" % [apply_before, apply_after])
	if draw_after != draw_before:
		_fail("Repeated catalog refresh redrew preview renderer: before=%d after=%d" % [draw_before, draw_after])
	print("PART_PREVIEW_TEXTURE_CACHE_PROBE ok apply=%d noop=%d draw=%d" % [apply_after, noop_after, draw_after])
	quit()
