extends SceneTree

const UILayoutTokens := preload("res://scripts/ui_layout_tokens.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_vec_close(actual: Vector2, expected: Vector2, label: String) -> void:
	if actual.distance_to(expected) > 0.01:
		_fail("%s mismatch. expected=%s actual=%s" % [label, str(expected), str(actual)])


func _init() -> void:
	var base := Rect2(Vector2(100.0, 80.0), Vector2(220.0, 60.0))
	var unchanged := UILayoutTokens.to_screen_rect(base, UILayoutTokens.DESIGN_SIZE)
	if unchanged != base:
		_fail("Design-size screen rect should be unchanged.")
	var wide := Vector2(1920.0, 1080.0)
	var wide_rect := UILayoutTokens.to_screen_rect(base, wide)
	_assert_vec_close(wide_rect.position, base.position * 1.5, "16:9 scaled position")
	_assert_vec_close(wide_rect.size, base.size * 1.5, "16:9 scaled size")
	var letterbox := Vector2(1920.0, 1200.0)
	var letterbox_rect := UILayoutTokens.to_screen_rect(base, letterbox)
	_assert_vec_close(letterbox_rect.position, Vector2(0.0, 60.0) + base.position * 1.5, "letterbox position")
	_assert_vec_close(letterbox_rect.size, base.size * 1.5, "letterbox size")
	var local_rect := UILayoutTokens.to_local_rect(base, letterbox)
	_assert_vec_close(local_rect.position, base.position * 1.5, "local position")
	_assert_vec_close(local_rect.size, base.size * 1.5, "local size")
	for rect in [
		UILayoutTokens.settings_title_rect(),
		UILayoutTokens.settings_options_button_rect(),
		UILayoutTokens.settings_scroll_rect(),
		UILayoutTokens.scout_title_rect(),
		UILayoutTokens.scout_options_button_rect(),
		UILayoutTokens.loading_panel_rect(),
	]:
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			_fail("Responsive token returned invalid rect: %s" % str(rect))
	print("LAYOUT_TOKENS_RESPONSIVE_CONTRACT_PROBE ok")
	quit(0)
