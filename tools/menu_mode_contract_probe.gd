extends SceneTree

const MODE_PATH := "res://scripts/modes/menu_mode.gd"
const MAIN_PATH := "res://scripts/main.gd"
const MenuModeScript := preload("res://scripts/modes/menu_mode.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(MODE_PATH):
		_fail("Missing MenuMode script.")
		return
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MODE_PATH))
	for token in [
		"class_name MenuMode",
		"MODE_KEY := \"menu\"",
		"func bind",
		"func enter_intent",
		"func commit_enter",
		"func show_intent",
		"func update_main_menu",
		"func move_selection",
		"func select_index",
		"func pointer_hover_intent",
		"func pointer_press_intent",
		"func main_menu_action",
		"func input_action_intent",
		"func exit_intent",
		"func commit_exit",
	]:
		if source.find(token) < 0:
			_fail("MenuMode missing token: %s" % token)
			return
	for forbidden in ["Input.", "FileAccess.open", "DirAccess", "JSON.parse_string", "active_units", "all_units", "_begin_battle", "_show_editor", "_show_settings"]:
		if source.find(forbidden) >= 0:
			_fail("MenuMode should stay menu-boundary only; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const MenuMode = preload(\"res://scripts/modes/menu_mode.gd\")",
		"var menu_mode_owner: MenuMode",
			"menu_mode_owner = MenuMode.new()",
			"menu_mode_owner.bind(self, menu_controller, menu_view)",
			"func _commit_menu_mode_enter",
			"func _commit_menu_mode_exit",
			"menu_mode_owner.enter_intent",
			"menu_mode_owner.commit_enter",
			"menu_mode_owner.exit_intent",
			"menu_mode_owner.commit_exit",
			"func _menu_mode_show_intent",
			"menu_mode_owner.show_intent",
			"menu_mode_owner.update_main_menu",
			"menu_mode_owner.move_selection",
			"menu_mode_owner.select_index",
			"menu_mode_owner.pointer_hover_intent",
			"menu_mode_owner.pointer_press_intent",
			"menu_mode_owner.main_menu_action",
			"menu_mode_owner.input_action_intent",
			"func _menu_pointer_hover_intent",
			"func _menu_pointer_press_intent",
			"func _menu_move_selection_intent",
			"func _menu_select_index_intent",
			"func _menu_input_action_intent",
			"func _apply_menu_input_action",
			"func _apply_menu_selection_intent",
			"func _menu_main_action",
			"var show_intent := _menu_mode_show_intent(preloaded, loading_queued)",
			"String(show_intent.get(\"reason\", \"menu\"))",
			"_commit_menu_mode_enter(nav_reason, payload)",
			"_commit_menu_mode_exit(reason, payload)",
		]:
		if main_source.find(token) < 0:
			_fail("main.gd missing MenuMode wiring token: %s" % token)
			return
	var mode = MenuModeScript.new()
	if mode.mode_key() != "menu":
		_fail("MenuMode mode_key mismatch: %s" % mode.mode_key())
		return
	var enter_intent: Dictionary = mode.enter_intent("startup", {"boot": true})
	if String(enter_intent.get("mode_key", "")) != "menu" or bool(enter_intent.get("bound", true)):
		_fail("Unbound enter_intent mismatch: %s" % str(enter_intent))
		return
	if not mode.commit_enter(enter_intent) or mode.enter_count != 1:
		_fail("MenuMode commit_enter failed.")
		return
	if mode.commit_enter({"mode_key": "battle"}):
		_fail("MenuMode should reject wrong-mode enter commits.")
		return
	var show_wait: Dictionary = mode.show_intent(false, true, "menu")
	if bool(show_wait.get("should_apply", true)) or not bool(show_wait.get("loading_queued", false)):
		_fail("MenuMode show_intent should hold while loading is queued: %s" % str(show_wait))
		return
	var show_now: Dictionary = mode.show_intent(true, false, "menu")
	if not bool(show_now.get("should_apply", false)) or bool(show_now.get("loading_queued", true)) or not bool(show_now.get("preloaded", false)):
		_fail("MenuMode show_intent should apply when preloaded: %s" % str(show_now))
		return
	if mode.update_main_menu("en", 1, "STD", ""):
		_fail("Unbound MenuMode should not apply menu updates.")
		return
	var moved: Dictionary = mode.move_selection(1, 0, 7)
	if int(moved.get("selected_index", -1)) != 1 or bool(moved.get("used_controller", true)):
		_fail("Unbound MenuMode move_selection fallback mismatch: %s" % str(moved))
		return
	var wrapped: Dictionary = mode.move_selection(-1, 0, 7)
	if int(wrapped.get("selected_index", -1)) != 6:
		_fail("Unbound MenuMode move_selection should wrap: %s" % str(wrapped))
		return
	var selected: Dictionary = mode.select_index(99, 7)
	if int(selected.get("selected_index", -1)) != 6:
		_fail("Unbound MenuMode select_index should clamp: %s" % str(selected))
		return
	var hover_same: Dictionary = mode.pointer_hover_intent(0, 0, 7)
	if bool(hover_same.get("handled", true)) or String(hover_same.get("input_source", "")) != "pointer_hover":
		_fail("Unbound MenuMode same-index pointer hover should be ignored: %s" % str(hover_same))
		return
	var hover_next: Dictionary = mode.pointer_hover_intent(2, 0, 7)
	if not bool(hover_next.get("handled", false)) or String(hover_next.get("kind", "")) != "selection" or int(hover_next.get("selected_index", -1)) != 2:
		_fail("Unbound MenuMode pointer hover intent mismatch: %s" % str(hover_next))
		return
	var press_intent: Dictionary = mode.pointer_press_intent(99, 7)
	if not bool(press_intent.get("handled", false)) or String(press_intent.get("kind", "")) != "activate" or int(press_intent.get("index", -1)) != 6:
		_fail("Unbound MenuMode pointer press intent mismatch: %s" % str(press_intent))
		return
	var action: Dictionary = mode.main_menu_action(2)
	if String(action.get("action", "unexpected")) != "" or int(action.get("index", -1)) != 2:
		_fail("Unbound MenuMode action fallback mismatch: %s" % str(action))
		return
	var up_intent: Dictionary = mode.input_action_intent("menu_up", 0, 7)
	if String(up_intent.get("kind", "")) != "selection" or int(up_intent.get("selected_index", -1)) != 6:
		_fail("Unbound MenuMode menu_up intent mismatch: %s" % str(up_intent))
		return
	var confirm_intent: Dictionary = mode.input_action_intent("menu_confirm", 3, 7)
	if String(confirm_intent.get("kind", "")) != "activate" or int(confirm_intent.get("index", -1)) != 3:
		_fail("Unbound MenuMode menu_confirm intent mismatch: %s" % str(confirm_intent))
		return
	var ignored_intent: Dictionary = mode.input_action_intent("other", 3, 7)
	if bool(ignored_intent.get("handled", true)):
		_fail("Unbound MenuMode unknown input should be ignored: %s" % str(ignored_intent))
		return
	var exit_intent: Dictionary = mode.exit_intent("navigate")
	if not mode.commit_exit(exit_intent) or mode.exit_count != 1:
		_fail("MenuMode commit_exit failed.")
		return
	print("MENU_MODE_CONTRACT_PROBE ok")
	quit(0)
