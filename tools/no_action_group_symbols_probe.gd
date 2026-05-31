extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _latest_unit_path(unit_name: String) -> String:
	var dir := DirAccess.open("user://saved_units")
	if dir == null:
		return ""
	var best_path := ""
	var best_time := -1
	for file_name in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var path := "user://saved_units/%s" % file_name
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if not (parsed is Dictionary):
			continue
		if String(Dictionary(parsed).get("unit_name", "")) != unit_name:
			continue
		var modified := int(FileAccess.get_modified_time(path))
		if modified >= best_time:
			best_time = modified
			best_path = path
	return best_path


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var path := _latest_unit_path("2")
	if path == "":
		_fail("No saved unit named 2 found.")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Cannot open saved unit 2.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON is invalid.")
		return
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	var role_key := String(saved.get("unit_role", "hero"))
	var stats: Dictionary = main._compute_unit_stats(1, role_key, -1, unit_bp)
	if not bool(stats.get("teamedit_runtime_topology", false)):
		_fail("Saved unit 2 is not using canonical TeamEdit runtime topology: %s" % String(stats.get("legacy_topology_note", "")))
		return
	if not Array(stats.get("attack_groups", [])).is_empty():
		_fail("Saved unit runtime still contains attack_groups.")
		return
	if Array(stats.get("runtime_topology_segments", [])).is_empty():
		_fail("Saved unit runtime has no topology segments.")
		return
	for raw_binding in Array(stats.get("runtime_module_bindings", [])):
		if raw_binding is Dictionary and not bool(Dictionary(raw_binding).get("runtime_valid", false)):
			_fail("Runtime module binding invalid: %s" % String(Dictionary(raw_binding).get("binding_valid_note", "")))
			return
	print("NO_ACTION_GROUP_SYMBOLS_PROBE path=%s segments=%d bindings=%d" % [ProjectSettings.globalize_path(path), Array(stats.get("runtime_topology_segments", [])).size(), Array(stats.get("runtime_module_bindings", [])).size()])
	quit()
