extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _assert_vec(actual: Vector2, expected: Vector2, message: String) -> void:
	if not actual.is_equal_approx(expected):
		_fail("%s expected=%s actual=%s" % [message, str(expected), str(actual)])


func _assert_color(actual: Color, expected: Color, message: String) -> void:
	if not actual.is_equal_approx(expected):
		_fail("%s expected=%s actual=%s" % [message, str(expected), str(actual)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor(true)

	var hero_role := "hero"
	main.editor_role_index = MainScene.ROLE_ORDER.find(hero_role)
	main.editor_panel_mode = "load"
	main.editor_load_mode = "unit"
	main.editor_template_menu_open = true
	var selected_archetype := String(MainScene.ARCHETYPE_ORDER[1])
	var hero_bp: Dictionary = main._editor_current_blueprint()
	hero_bp["archetype"] = selected_archetype
	main._update_editor_ui(true)

	_check(main.editor_template_panel != null and main.editor_template_panel.visible, "Hero template drawer panel should stay visible after full editor refresh.")
	_check(main.editor_section_labels.has("template") and main.editor_section_labels["template"].visible, "Hero template drawer title should stay visible after full editor refresh.")
	var selected_button: Button = main.editor_archetype_buttons[selected_archetype]
	_check(selected_button.visible and not selected_button.disabled, "Selected archetype template button should be visible and enabled.")
	_assert_vec(selected_button.position, Vector2(1074.0, 406.0), "Selected archetype template button position mismatch.")
	_assert_color(selected_button.modulate, Color(0.32, 0.95, 1.0, 1.0), "Selected archetype template button color mismatch.")
	var first_barrier_button: Button = main.editor_template_buttons[MainScene.ARCHETYPE_ORDER.size()]
	_check(not first_barrier_button.visible and first_barrier_button.disabled, "Barrier template button should be hidden while editing hero templates.")

	var barrier_role := "barrier"
	main.editor_role_index = MainScene.ROLE_ORDER.find(barrier_role)
	main.editor_panel_mode = "load"
	main.editor_load_mode = "unit"
	main.editor_template_menu_open = true
	main._update_editor_ui(true)

	_check(main.editor_template_panel.visible, "Barrier template drawer panel should stay visible after full editor refresh.")
	var first_archetype_button: Button = main.editor_template_buttons[0]
	_check(not first_archetype_button.visible and first_archetype_button.disabled, "Archetype template button should be hidden while editing barrier templates.")
	first_barrier_button = main.editor_template_buttons[MainScene.ARCHETYPE_ORDER.size()]
	_check(first_barrier_button.visible and not first_barrier_button.disabled, "Barrier template button should be visible and enabled.")
	_assert_vec(first_barrier_button.position, Vector2(940.0, 406.0), "Barrier template button position mismatch.")

	if not failures.is_empty():
		print("UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE failures=%s" % " | ".join(failures))
		quit(1)
		return
	print("UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=%s barrier=%s" % [selected_archetype, first_barrier_button.name])
	quit()
