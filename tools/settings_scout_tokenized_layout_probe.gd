extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const UILayoutTokens := preload("res://scripts/ui_layout_tokens.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_rect(control: Control, expected: Rect2, label: String) -> void:
	var actual := Rect2(control.position, control.size)
	if actual.position.distance_to(expected.position) > 0.01 or actual.size.distance_to(expected.size) > 0.01:
		_fail("%s rect mismatch. expected=%s actual=%s" % [label, str(expected), str(actual)])


func _assert_position_width(control: Control, expected: Rect2, label: String) -> void:
	if control.position.distance_to(expected.position) > 0.01 or absf(control.size.x - expected.size.x) > 0.01:
		_fail("%s position/width mismatch. expected=%s actual=%s" % [label, str(expected), str(Rect2(control.position, control.size))])
	if control.size.y < expected.size.y:
		_fail("%s height should not be smaller than token height. expected=%s actual=%s" % [label, expected.size.y, control.size.y])


func _child(root: Node, child_name: String) -> Control:
	var found := root.find_child(child_name, true, false)
	if not (found is Control):
		_fail("Missing control: %s" % child_name)
	return found


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_settings(true)
	var viewport_size := main._ui_viewport_size()
	_assert_rect(_child(main.settings_layer, "SettingsTitle"), UILayoutTokens.to_screen_rect(UILayoutTokens.settings_title_rect(), viewport_size), "Settings title")
	_assert_rect(_child(main.settings_layer, "SettingsBackButton"), UILayoutTokens.to_screen_rect(UILayoutTokens.settings_options_button_rect(), viewport_size), "Settings options")
	_assert_rect(_child(main.settings_layer, "SettingsCategorysound"), UILayoutTokens.to_screen_rect(UILayoutTokens.settings_category_button_rect(0), viewport_size), "Settings category")
	_assert_rect(main.settings_scroll_container, UILayoutTokens.to_screen_rect(UILayoutTokens.settings_scroll_rect(), viewport_size), "Settings scroll")
	_assert_rect(main.settings_reset_button, UILayoutTokens.to_screen_rect(UILayoutTokens.settings_reset_button_rect(), viewport_size), "Settings reset")
	main._show_scout(MainScene.MODE_AI, true)
	_assert_rect(_child(main.scout_layer, "ScoutTitle"), UILayoutTokens.to_screen_rect(UILayoutTokens.scout_title_rect(), viewport_size), "Scout title")
	_assert_rect(_child(main.scout_layer, "ScoutTimer"), UILayoutTokens.to_screen_rect(UILayoutTokens.scout_timer_rect(), viewport_size), "Scout timer")
	_assert_position_width(_child(main.scout_layer, "ScoutStartButton"), UILayoutTokens.to_screen_rect(UILayoutTokens.scout_start_button_rect(), viewport_size), "Scout start")
	_assert_position_width(_child(main.scout_layer, "ScoutMenuButton"), UILayoutTokens.to_screen_rect(UILayoutTokens.scout_options_button_rect(), viewport_size), "Scout options")
	print("SETTINGS_SCOUT_TOKENIZED_LAYOUT_PROBE ok")
	quit(0)
