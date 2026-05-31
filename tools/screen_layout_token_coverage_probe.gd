extends SceneTree

const MAIN_PATH := "res://scripts/main.gd"
const TOKENS_PATH := "res://scripts/ui_layout_tokens.gd"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _function_body(source: String, function_name: String) -> String:
	var marker := "func %s" % function_name
	var start := source.find(marker)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + marker.length())
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _init() -> void:
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	var token_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(TOKENS_PATH))
	if main_source.is_empty() or token_source.is_empty():
		_fail("Could not read layout sources.")
	for token in [
		"static func screen_region",
		"saved_units_canvas_panel",
		"saved_units_detail_panel",
		"editor_canvas_panel",
		"editor_drawer_panel",
		"editor_options_button",
		"editor_board",
		"battle_menu_button",
		"battle_help",
	]:
		if token_source.find(token) < 0:
			_fail("UILayoutTokens missing screen region token: %s" % token)
	for helper in ["func _apply_token_rect", "func _make_token_label", "func _add_token_ui_rect"]:
		if main_source.find(helper) < 0:
			_fail("main.gd missing token application helper: %s" % helper)
	var saved_body := _function_body(main_source, "_build_saved_units_ui(")
	for token in [
		"_add_token_ui_rect(root, \"SavedUnitsCanvasPanel\", \"saved_units_canvas_panel\"",
		"_add_token_ui_rect(root, \"SavedUnitsDetailPanel\", \"saved_units_detail_panel\"",
		"_make_token_label(root, \"SavedUnitsTitle\"",
		"_make_token_label(root, \"SavedUnitsHint\"",
		"_apply_token_rect(back_button, \"saved_units_options_button\")",
		"UILayoutTokens.saved_units_filter_button_rect(i)",
	]:
		if saved_body.find(token) < 0:
			_fail("Saved Units top layout should use token path: %s" % token)
	var editor_body := _function_body(main_source, "_build_editor_ui(")
	for token in [
		"_apply_token_rect(editor_back_button, \"editor_options_button\")",
		"_add_token_ui_rect(root, \"EditorCanvasPanel\", \"editor_canvas_panel\"",
		"_add_token_ui_rect(root, \"EditorDrawerPanel\", \"editor_drawer_panel\"",
		"_apply_token_rect(assembly_board_view, \"editor_board\")",
	]:
		if editor_body.find(token) < 0:
			_fail("Unit Edit top layout should use token path: %s" % token)
	var battle_body := _function_body(main_source, "_build_battle_ui(")
	for token in [
		"_apply_token_rect(battle_menu_button, \"battle_menu_button\")",
		"_make_token_label(hud, \"BattleHelp\"",
	]:
		if battle_body.find(token) < 0:
			_fail("Battle HUD top layout should use token path: %s" % token)
	for legacy_coord in [
		"Vector2(34.0, 76.0)",
		"Vector2(822.0, 76.0)",
		"Vector2(8.0, 70.0)",
		"Vector2(924.0, 76.0)",
		"Vector2(1092.0, 650.0)",
	]:
		if saved_body.find(legacy_coord) >= 0 or editor_body.find(legacy_coord) >= 0 or battle_body.find(legacy_coord) >= 0:
			_fail("Top-level UI build function still uses migrated naked coordinate: %s" % legacy_coord)
	print("SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok")
	quit(0)
