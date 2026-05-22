extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _function_block(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _forbidden_assignments(block: String) -> Array:
	var forbidden := []
	for pattern in [".text =", ".modulate ="]:
		if block.contains(pattern):
			forbidden.append(pattern)
	return forbidden


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if source.is_empty():
		_fail("Unable to read main.gd.")
		return
	for required in ["func _apply_ui_state", "func build_editor_ui_state", "func build_battle_hud_state", "func build_torso_detail_state"]:
		if not source.contains(required):
			_fail("Missing UI state entrypoint: %s" % required)
			return
	for signature in ["func _update_settings_ui", "func _update_battle_ui"]:
		var block := _function_block(source, signature)
		if block.is_empty():
			_fail("Unable to inspect %s." % signature)
			return
		var forbidden := _forbidden_assignments(block)
		if not forbidden.is_empty():
			_fail("%s still has direct hot-path UI assignments: %s" % [signature, ", ".join(forbidden)])
			return
		if not block.contains("_apply_ui_state"):
			_fail("%s does not apply UI state snapshots." % signature)
			return
	var torso_block := _function_block(source, "func _refresh_torso_detail_view")
	if torso_block.is_empty() or not torso_block.contains("set_detail") or not torso_block.contains("set_binding_state"):
		_fail("Torso detail refresh is not using the retained detail view state API.")
		return
	print("DIRECT_UI_WRITE_HOTPATH_PROBE ok")
	quit(0)
