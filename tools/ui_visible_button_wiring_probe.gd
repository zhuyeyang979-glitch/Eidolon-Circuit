extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _scan_visible_buttons(node: Node, page_name: String, failures: Array) -> int:
	var count := 0
	if node is Button:
		var button := node as Button
		if button.is_visible_in_tree() and not button.disabled and not (button is ColorPickerButton):
			count += 1
			if button.get_signal_connection_list(&"pressed").is_empty():
				failures.append("%s/%s" % [page_name, button.name])
	for child in node.get_children():
		count += _scan_visible_buttons(child, page_name, failures)
	return count


func _check_page(root_node: Node, page_name: String, counts: Dictionary, failures: Array) -> void:
	var count := _scan_visible_buttons(root_node, page_name, failures)
	if count <= 0:
		_fail("%s should expose at least one enabled visible button." % page_name)
	counts[page_name] = count


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	await process_frame
	main.loading_auto_transitions_enabled = false
	var failures: Array = []
	var counts := {}
	main._show_menu(true)
	await process_frame
	_check_page(main.menu_layer, "menu", counts, failures)
	main._show_saved_units_library("", "menu", false, true)
	await process_frame
	_check_page(main.saved_units_layer, "saved_units", counts, failures)
	main._show_editor(true)
	await process_frame
	_check_page(main.editor_layer, "editor", counts, failures)
	main._show_settings(true)
	await process_frame
	_check_page(main.settings_layer, "settings_root", counts, failures)
	main._show_settings_category("input")
	await process_frame
	_check_page(main.settings_layer, "settings_input", counts, failures)
	main._show_settings_category("video")
	await process_frame
	_check_page(main.settings_layer, "settings_video", counts, failures)
	main._show_training_config(true)
	await process_frame
	_check_page(main.scout_layer, "scout", counts, failures)
	main._begin_battle(MainScene.MODE_PVP, true)
	main._toggle_battle_runtime_menu()
	await process_frame
	_check_page(main.hud_layer, "battle_runtime", counts, failures)
	if not failures.is_empty():
		_fail("Enabled visible buttons without pressed wiring: %s" % ", ".join(failures))
	print("UI_VISIBLE_BUTTON_WIRING_PROBE ok counts=%s" % str(counts))
	quit(0)
