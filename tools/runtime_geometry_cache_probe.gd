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
		if String(Dictionary(parsed).get("unit_name", "")) != "2":
			continue
		var modified := int(FileAccess.get_modified_time(path))
		if modified >= best_time:
			best_time = modified
			best_path = path
	return best_path


func _load_unit2(main) -> Dictionary:
	var path := _latest_unit2_path()
	if path == "":
		_fail("No saved unit named 2 found.")
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON is invalid.")
		return {}
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var role_key := String(saved.get("unit_role", "hero"))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	var note: String = main._training_blueprint_illegal_note(1, role_key, unit_bp)
	if note != "":
		_fail("Unit 2 should be legal for training, got: %s" % note)
		return {}
	return {"role": role_key, "blueprint": unit_bp}


func _spawn_training_unit2(main):
	var unit := _load_unit2(main)
	main.training_import_units = [{"role": unit["role"], "blueprint": Dictionary(unit["blueprint"]).duplicate(true)}]
	main.training_import_role_key = String(unit["role"])
	main.training_import_blueprint = Dictionary(unit["blueprint"]).duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	var p1_units: Dictionary = main.active_units.get(1, {})
	return p1_units.get("hero", null)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var hero = _spawn_training_unit2(main)
	if hero == null:
		_fail("Training hero missing.")
		return
	var segment_builds_before := int(hero.runtime_geometry_cache_builds)
	var collider_builds_before := int(hero.runtime_geometry_collider_builds)
	var first_segments: Array = hero._runtime_topology_world_segments(true, true)
	var segment_builds_after_first := int(hero.runtime_geometry_cache_builds)
	var second_segments: Array = hero._runtime_topology_world_segments(true, true)
	var segment_builds_after_second := int(hero.runtime_geometry_cache_builds)
	if first_segments.size() <= 0:
		_fail("Runtime segments missing.")
		return
	if first_segments.size() != second_segments.size():
		_fail("Cached segment count changed inside one frame.")
		return
	if segment_builds_after_first <= segment_builds_before:
		_fail("First segment read did not build cache.")
		return
	if segment_builds_after_second != segment_builds_after_first:
		_fail("Second segment read rebuilt cache in the same frame.")
		return
	var first_colliders: Array = hero.part_colliders()
	var collider_builds_after_first := int(hero.runtime_geometry_collider_builds)
	var second_colliders: Array = hero.part_colliders()
	var collider_builds_after_second := int(hero.runtime_geometry_collider_builds)
	if first_colliders.size() <= 0:
		_fail("Runtime colliders missing.")
		return
	if first_colliders.size() != second_colliders.size():
		_fail("Cached collider count changed inside one frame.")
		return
	if collider_builds_after_first <= collider_builds_before:
		_fail("First collider read did not build cache.")
		return
	if collider_builds_after_second != collider_builds_after_first:
		_fail("Second collider read rebuilt cache in the same frame.")
		return
	if int(hero.runtime_geometry_cache_hits) <= 0:
		_fail("Runtime geometry cache recorded no hits.")
		return
	print("RUNTIME_GEOMETRY_CACHE_PROBE ok segments=%d colliders=%d hits=%d" % [first_segments.size(), first_colliders.size(), int(hero.runtime_geometry_cache_hits)])
	quit()
