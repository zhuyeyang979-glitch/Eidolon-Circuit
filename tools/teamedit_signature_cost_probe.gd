extends SceneTree

const MAIN_PATH := "res://scripts/main.gd"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string(MAIN_PATH)
	var forbidden := [
		"str(next_snapshot)",
		"str(next_data)",
		"str(next_plugins)",
		"str(next_software)",
		"str(next_candidates)",
		"str(next_entries)",
		"str(next_stat_entries)",
		"str(next_lines)",
	]
	for token in forbidden:
		if source.contains(token):
			_fail("Hot-path expensive signature token remains: %s" % token)
	if not source.contains("next_revision_key"):
		_fail("AssemblyBoardView.set_board does not accept a cheap revision key.")
	print("TEAMEDIT_SIGNATURE_COST_PROBE ok")
	quit()
