extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failures: Array = []

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	failures.append(message)


func _require_button(main, key: String) -> Button:
	if not main.editor_action_buttons.has(key):
		_check(false, "Missing editor action button: %s" % key)
		return null
	var button: Button = main.editor_action_buttons[key]
	_check(button != null, "Null editor action button: %s" % key)
	return button


func _rect_overlap(a: Control, b: Control) -> bool:
	if a == null or b == null:
		return false
	return a.get_global_rect().intersects(b.get_global_rect(), true)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor()
	var role_key := "hero"
	main.editor_role_index = MainScene.ROLE_ORDER.find(role_key)
	while Array(main.blueprints[1][role_key]).size() < 3:
		main._create_editor_role_page(role_key)
	main._select_adjacent_editor_unit_page(1)
	main._update_editor_ui(true)
	var prev_unit := _require_button(main, "prev_unit")
	var next_unit := _require_button(main, "next_unit")
	_check(prev_unit.visible and next_unit.visible, "Unit page buttons should be visible on the unit editor.")
	_check(not prev_unit.disabled and not next_unit.disabled, "Unit page buttons should be enabled when the current role has multiple pages.")
	var current_index := int(main.editor_unit_indices[role_key])
	main._editor_action("next_unit")
	_check(int(main.editor_unit_indices[role_key]) != current_index, "Next unit button did not select another unit page.")
	_check(int(main.active_roster_indices[1][role_key]) == int(main.editor_unit_indices[role_key]), "Unit page switch did not sync active roster index.")
	_check(int(main.editor_roster_page) == int(floori(float(main.editor_unit_indices[role_key]) / float(maxi(1, main.editor_roster_slot_buttons.size())))), "Unit page switch did not sync roster overview page.")
	var feedback: Label = main.editor_save_unit_feedback_label
	_check(feedback != null, "Save unit feedback label missing.")
	if feedback != null:
		feedback.text = "保存成功：Probe Layout"
		feedback.visible = true
		main._layout_editor_save_unit_feedback()
		_check(not _rect_overlap(feedback, main.editor_board_hint_label), "Save unit feedback overlaps the board hint.")
		_check(not _rect_overlap(feedback, main.editor_section_labels["roster_overview"]) and not _rect_overlap(feedback, main.editor_section_labels["roster_page"]), "Save unit feedback overlaps the roster overview.")
		_check(not _rect_overlap(feedback, _require_button(main, "save_canvas")), "Save unit feedback overlaps the Save Unit button.")
	main.editor_panel_mode = "parts"
	main._update_editor_ui(true)
	var page_before := int(main.editor_catalog_page)
	main._editor_action("next_catalog")
	_check(main._editor_current_catalog_max_page() <= 0 or int(main.editor_catalog_page) != page_before, "Parts catalog next button did not turn the page.")
	main.editor_panel_mode = "load"
	main.editor_load_mode = "unit"
	main.editor_load_page = 10000
	main._update_editor_ui(true)
	_check(int(main.editor_load_page) <= int(main._editor_load_max_page()), "Load page was not clamped to the legal range.")
	if not failures.is_empty():
		print("UNIT_EDITOR_PAGINATION_LAYOUT_PROBE failures=%s" % " | ".join(failures))
		quit(1)
		return
	print("UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=%d page=%d catalog=%d load=%d feedback=%s" % [
		int(main.editor_unit_indices[role_key]),
		int(main.editor_roster_page),
		int(main.editor_catalog_page),
		int(main.editor_load_page),
		str(feedback.get_global_rect() if feedback != null else Rect2()),
	])
	quit()
