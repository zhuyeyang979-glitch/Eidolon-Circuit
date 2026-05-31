extends SceneTree

const MAIN_PATH := "res://scripts/main.gd"
const NAV_PATH := "res://scripts/services/navigation_service.gd"


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
	var nav_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(NAV_PATH))
	if main_source.is_empty() or nav_source.is_empty():
		_fail("Could not read navigation sources.")
	for token in [
		"const PAGE_MENU",
		"const PAGE_EDITOR",
		"const PAGE_SAVED_UNITS",
		"const PAGE_SCOUT",
		"const PAGE_SETTINGS",
		"const PAGE_BATTLE",
		"const ACTION_NAVIGATE_MENU",
		"const ACTION_NAVIGATE_SETTINGS",
		"const ACTION_NAVIGATE_RETURN_TARGET",
		"static func route_action",
	]:
		if nav_source.find(token) < 0:
			_fail("NavigationService missing route constant/API: %s" % token)
	for token in [
		"return route_action(ACTION_CLOSE",
		"return route_action(ACTION_NAVIGATE_MENU",
		"return route_action(ACTION_NAVIGATE_SETTINGS",
		"return route_action(ACTION_NAVIGATE_RETURN_TARGET",
		"return route_action(ACTION_NAVIGATE_EDITOR_PRESERVE",
	]:
		if nav_source.find(token) < 0:
			_fail("NavigationService should resolve router actions through route_action(): %s" % token)
	var navigate_body := _function_body(main_source, "_navigate_page(")
	if navigate_body.is_empty():
		_fail("main.gd missing unified _navigate_page(route_action).")
	for token in [
		"NavigationService.ACTION_CLOSE",
		"NavigationService.ACTION_NAVIGATE_MENU",
		"NavigationService.ACTION_NAVIGATE_SETTINGS",
		"NavigationService.ACTION_NAVIGATE_RETURN_TARGET",
	]:
		if navigate_body.find(token) < 0:
			_fail("_navigate_page missing action branch: %s" % token)
	var page_options_body := _function_body(main_source, "_execute_page_options_action(")
	if page_options_body.find("_navigate_page(routed)") < 0:
		_fail("_execute_page_options_action should delegate to _navigate_page().")
	if page_options_body.find("match String(action.get") >= 0 or page_options_body.find("_show_menu(") >= 0 or page_options_body.find("_show_settings(") >= 0:
		_fail("_execute_page_options_action should not interpret page actions directly.")
	var target_body := _function_body(main_source, "_navigate_to_page_target(")
	if target_body.find("navigation_service.resolve_target_navigation(target_state, reason)") < 0 or target_body.find("_navigate_page(action)") < 0:
		_fail("_navigate_to_page_target should resolve and execute RouteAction through NavigationService.")
	print("NAVIGATION_ROUTE_ACTION_CONTRACT_PROBE ok")
	quit(0)
