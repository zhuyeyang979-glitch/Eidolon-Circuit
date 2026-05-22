extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _card_apply_total(main) -> int:
	var total := 0
	for button in main.editor_catalog_buttons:
		if button != null:
			total += int(button.set_card_apply_count)
	return total


func _card_noop_total(main) -> int:
	var total := 0
	for button in main.editor_catalog_buttons:
		if button != null:
			total += int(button.set_card_noop_count)
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
	var applied_before := _card_apply_total(main)
	var noop_before := _card_noop_total(main)
	main._update_editor_catalog_buttons(role_key, unit_bp)
	main._update_editor_catalog_buttons(role_key, unit_bp)
	var applied_after := _card_apply_total(main)
	var noop_after := _card_noop_total(main)
	if applied_after != applied_before:
		_fail("Repeated catalog update applied card redraws: before=%d after=%d" % [applied_before, applied_after])
	if noop_after <= noop_before:
		_fail("Repeated catalog update did not hit card no-op path.")
	print("CATALOG_CARD_SET_CARD_NOOP_PROBE ok apply=%d noop=%d" % [applied_after, noop_after])
	quit()
