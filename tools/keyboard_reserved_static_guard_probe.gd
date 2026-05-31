extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _function_block(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	return source.substr(start, source.length() - start if next < 0 else next - start)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for required in [
		"func _is_keyboard_enter_event",
		"func _is_keyboard_escape_event",
		"func _route_reserved_keyboard_input",
		"_bind_key(\"ui_numeric_submit\", KEY_ENTER)",
		"_bind_key(\"ui_numeric_submit\", KEY_KP_ENTER)",
		"_bind_key(\"ui_detail_close\", KEY_ESCAPE)",
		"_bind_key(\"battle_pause\", KEY_ESCAPE)",
	]:
		if not source.contains(required):
			_fail("Missing reserved keyboard contract item: %s" % required)
	var register_block := _function_block(source, "func _register_inputs")
	if register_block.contains("_bind_key(\"menu_confirm\", KEY_ENTER") or register_block.contains("_bind_key(\"menu_back\", KEY_ESCAPE"):
		_fail("menu_confirm/menu_back must not bind keyboard Enter/Escape.")
	for signature in [
		"func _handle_menu_input",
		"func _handle_saved_units_input",
		"func _handle_scout_input",
		"func _handle_editor_input",
		"func _handle_settings_input",
	]:
		var block := _function_block(source, signature)
		if block.contains("KEY_ENTER") or block.contains("KEY_ESCAPE"):
			_fail("%s directly references KEY_ENTER/KEY_ESCAPE." % signature)
	var battle_block := _function_block(source, "func _handle_battle_input(delta")
	if not battle_block.contains("battle_pause"):
		_fail("Battle input should use battle_pause instead of menu_back for Escape pause.")
	print("KEYBOARD_RESERVED_STATIC_GUARD_PROBE ok")
	quit()
