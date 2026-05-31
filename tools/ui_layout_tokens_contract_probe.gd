extends SceneTree

const UILayoutTokens := preload("res://scripts/ui_layout_tokens.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var design := Rect2(Vector2.ZERO, UILayoutTokens.DESIGN_SIZE)
	if UILayoutTokens.DESIGN_SIZE != Vector2(1280.0, 720.0):
		_fail("Design size must match the project viewport.")
	var regions := {
		"left_sidebar": UILayoutTokens.left_sidebar_rect(),
		"right_sidebar": UILayoutTokens.right_sidebar_rect(),
		"main_board": UILayoutTokens.main_board_rect(),
		"top_dock": UILayoutTokens.top_dock_rect(),
		"bottom_bar": UILayoutTokens.bottom_bar_rect(),
		"page_options": UILayoutTokens.page_options_rect(),
		"battle_runtime": UILayoutTokens.battle_runtime_options_rect(),
		"format_select": UILayoutTokens.format_select_panel_rect(),
		"loading": UILayoutTokens.loading_panel_rect(),
	}
	for key in regions.keys():
		var rect: Rect2 = regions[key]
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			_fail("%s has invalid size: %s" % [key, str(rect)])
		if not design.encloses(rect):
			_fail("%s should fit inside design viewport: %s" % [key, str(rect)])
	if UILayoutTokens.left_sidebar_rect().intersects(UILayoutTokens.top_dock_rect()):
		_fail("Top dock must not overlap the left dashboard/sidebar region.")
	if UILayoutTokens.right_sidebar_rect().intersects(UILayoutTokens.top_dock_rect()):
		_fail("Top dock must not overlap the right catalog/sidebar region.")
	if UILayoutTokens.main_menu_button_rect(1).position.y - UILayoutTokens.main_menu_button_rect(0).position.y != 56.0:
		_fail("Main menu row helper should preserve legacy 56px step.")
	if UILayoutTokens.page_options_button_rect(1).position.y - UILayoutTokens.page_options_button_rect(0).position.y != 32.0:
		_fail("Page options row helper should preserve legacy 32px step.")
	if UILayoutTokens.battle_runtime_button_rect(1).position.y - UILayoutTokens.battle_runtime_button_rect(0).position.y != 34.0:
		_fail("Runtime options row helper should preserve legacy 34px step.")
	if UILayoutTokens.modal_rect(Vector2(200.0, 100.0)).position != Vector2(540.0, 300.0):
		_fail("Modal helper should center with the shared y offset.")
	print("UI_LAYOUT_TOKENS_CONTRACT_PROBE ok")
	quit(0)
