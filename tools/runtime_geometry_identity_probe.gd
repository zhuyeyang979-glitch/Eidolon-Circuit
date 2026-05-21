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
		if not (parsed is Dictionary) or String(Dictionary(parsed).get("unit_name", "")) != "2":
			continue
		var mtime := int(FileAccess.get_modified_time(path))
		if mtime >= best_time:
			best_time = mtime
			best_path = path
	return best_path


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var path := _latest_unit2_path()
	if path == "":
		_fail("No saved unit named 2 found.")
	var parsed = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON is invalid.")
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var role_key := String(saved.get("unit_role", "hero"))
	var bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	var stats: Dictionary = main._compute_unit_stats(1, role_key, 0, bp)
	var stat_segments: Array = Array(stats.get("runtime_topology_segments", []))
	var stat_torso: Dictionary = {}
	for raw_segment in stat_segments:
		if raw_segment is Dictionary and String(Dictionary(raw_segment).get("part_kind", "")) == "torso":
			stat_torso = Dictionary(raw_segment)
			break
	if stat_torso.is_empty() or String(stat_torso.get("shape", "")) != "polygon" or Array(stat_torso.get("polygon_local", [])).size() < 3:
		_fail("Saved unit stats did not preserve a polygon TeamEdit torso.")
	main.training_import_units = [{"role": role_key, "blueprint": bp.duplicate(true)}]
	main.training_import_role_key = role_key
	main.training_import_blueprint = bp.duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	var hero = main.active_units[1]["hero"]
	if not main._is_live_unit(hero):
		_fail("Training hero missing.")
	var runtime_segments: Array = Array(hero.stats.get("runtime_topology_segments", []))
	if runtime_segments.size() != stat_segments.size():
		_fail("Runtime segment count differs from TeamEdit stats: %d vs %d" % [runtime_segments.size(), stat_segments.size()])
	var colliders: Array = hero.part_colliders()
	var collider_torso: Dictionary = {}
	for raw_collider in colliders:
		if raw_collider is Dictionary and String(Dictionary(raw_collider).get("part_kind", "")) == "torso":
			collider_torso = Dictionary(raw_collider)
			break
	if collider_torso.is_empty() or String(collider_torso.get("shape", "")) != "polygon" or Array(collider_torso.get("polygon", [])).size() != Array(stat_torso.get("polygon_local", [])).size():
		_fail("Runtime torso collider is not the same polygon topology as TeamEdit.")
	print("RUNTIME_GEOMETRY_IDENTITY_PROBE segments=%d torso_points=%d" % [runtime_segments.size(), Array(collider_torso.get("polygon", [])).size()])
	quit()
