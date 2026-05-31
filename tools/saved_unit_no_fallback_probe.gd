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
	if not bool(stats.get("teamedit_runtime_topology", false)):
		_fail("Saved unit stats are not marked direct TeamEdit runtime topology.")
	if not Array(stats.get("attack_groups", [])).is_empty():
		_fail("Saved unit stats still include legacy attack_groups.")
	if Array(stats.get("runtime_topology_segments", [])).is_empty():
		_fail("Saved unit has no runtime topology segments.")
	main.training_import_units = [{"role": role_key, "blueprint": bp.duplicate(true)}]
	main.training_import_role_key = role_key
	main.training_import_blueprint = bp.duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	var hero = main.active_units[1]["hero"]
	if not main._is_live_unit(hero):
		_fail("Runtime hero missing.")
	for legacy_name in ["Shell", "TopologyLine", "MuscleA", "MuscleB", "JointA", "JointB", "SpecialCore", "CoreProceduralArt"]:
		if hero.find_child(legacy_name, true, false) != null:
			_fail("Legacy visual node still exists on saved runtime hero: %s." % legacy_name)
	var torso_line = hero.get("torso_collision_line")
	if torso_line != null and torso_line.visible:
		_fail("Runtime hero is drawing legacy torso collision line.")
	var joint_lines = hero.get("joint_collision_lines")
	if joint_lines is Array:
		for line in joint_lines:
			if line != null and line.visible:
				_fail("Runtime hero is drawing legacy joint collision lines.")
	var joint_sprites = hero.get("joint_art_sprites")
	if joint_sprites is Array:
		for sprite in joint_sprites:
			if sprite != null and sprite.visible:
				_fail("Runtime hero is drawing legacy joint art sprites.")
	print("SAVED_UNIT_NO_FALLBACK_PROBE ok")
	quit()
