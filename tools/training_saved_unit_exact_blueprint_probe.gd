extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _latest_unit2_path() -> String:
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
		var data: Dictionary = parsed
		if String(data.get("unit_name", "")) != "2":
			continue
		var mtime := int(FileAccess.get_modified_time(path))
		if mtime >= best_time:
			best_time = mtime
			best_path = path
	return best_path


func _load_unit2(main) -> Dictionary:
	var path := _latest_unit2_path()
	if path == "":
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {}
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	unit_bp["role"] = String(saved.get("unit_role", "hero"))
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit_bp := _load_unit2(main)
	if unit_bp.is_empty():
		_fail("No legal saved unit named 2 is available for exact training import.")
		return
	main._apply_entry_pose_to_blueprint(unit_bp)
	var role_key := String(unit_bp.get("role", "hero"))
	var expected_stats: Dictionary = main._compute_unit_stats(1, role_key, -1, unit_bp)
	var expected_segments: Array = expected_stats.get("runtime_topology_segments", [])
	main.training_import_units = [{"role": role_key, "blueprint": unit_bp.duplicate(true)}]
	main.training_import_role_key = role_key
	main.training_import_blueprint = unit_bp.duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	var hero = main.active_units[1]["hero"]
	if not main._is_live_unit(hero):
		_fail("Training did not spawn the imported TeamEdit hero.")
	var actual_segments: Array = hero.stats.get("runtime_topology_segments", [])
	if actual_segments.size() != expected_segments.size():
		_fail("Training runtime segment count differs from saved blueprint: %d vs %d." % [actual_segments.size(), expected_segments.size()])
	for i in range(expected_segments.size()):
		var expected: Dictionary = expected_segments[i]
		var actual: Dictionary = actual_segments[i]
		for key in ["part_kind", "node_index", "a_local", "b_local", "radius"]:
			if str(expected.get(key, "")) != str(actual.get(key, "")):
				_fail("Training segment %d key %s changed: %s vs %s." % [i, key, str(actual.get(key, "")), str(expected.get(key, ""))])
	print("TRAINING_SAVED_UNIT_EXACT_BLUEPRINT_PROBE segments=%d" % actual_segments.size())
	quit()
