extends SceneTree

const MAIN_PATH := "res://scripts/main.gd"
const NAV_PATH := "res://scripts/services/navigation_service.gd"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _line_has_direct_game_state_write(line: String) -> bool:
	var stripped := line.strip_edges()
	if stripped.begins_with("#"):
		return false
	if not stripped.contains("game_state ="):
		return false
	if stripped.contains("==") or stripped.contains("!="):
		return false
	return true


func _init() -> void:
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	var nav_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(NAV_PATH))
	if main_source.is_empty() or nav_source.is_empty():
		_fail("Could not read navigation sources.")
	for token in ["func return_target_for", "func resolve_target_navigation", "func resolve_option_action", "func begin_transition", "func commit_transition"]:
		if nav_source.find(token) < 0:
			_fail("NavigationService missing router API: %s" % token)
	if main_source.find("return navigation_service.return_target_for(target_state, explicit_return_target)") < 0:
		_fail("_navigation_return_target_for should delegate to NavigationService.return_target_for().")
	if main_source.find("navigation_service.resolve_target_navigation(target_state, reason)") < 0:
		_fail("_navigate_to_page_target should delegate to NavigationService.resolve_target_navigation().")
	if main_source.find("navigation_service.resolve_option_action(action_key, current_subroute)") < 0:
		_fail("Page options should resolve through NavigationService.")
	var in_commit_page_state := false
	var direct_writes := []
	var lines := main_source.split("\n")
	for i in range(lines.size()):
		var line := String(lines[i])
		if line.begins_with("func "):
			in_commit_page_state = line.begins_with("func _commit_page_state(")
		if _line_has_direct_game_state_write(line) and not in_commit_page_state:
			direct_writes.append("%d:%s" % [i + 1, line.strip_edges()])
	if not direct_writes.is_empty():
		_fail("Only _commit_page_state may write game_state directly: %s" % ", ".join(direct_writes))
	print("NAVIGATION_ROUTER_SINGLE_SOURCE_PROBE ok")
	quit(0)
