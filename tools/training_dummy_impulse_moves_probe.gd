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
		var mtime := int(FileAccess.get_modified_time(path))
		if mtime >= best_time:
			best_time = mtime
			best_path = path
	return best_path


func _load_unit2(main) -> Dictionary:
	var path := _latest_unit2_path()
	if path == "":
		_fail("No saved unit named 2 found.")
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Cannot open saved unit 2.")
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON is invalid.")
		return {}
	return main._json_restore_value(Dictionary(parsed))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var saved := _load_unit2(main)
	var role_key := String(saved.get("unit_role", "hero"))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	main.training_import_units = [{"role": role_key, "blueprint": unit_bp.duplicate(true)}]
	main.training_import_role_key = role_key
	main.training_import_blueprint = unit_bp.duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	var dummy = main.active_units[2]["hero"]
	if not main._is_live_unit(dummy):
		_fail("Training dummy did not spawn.")
		return
	if not bool(dummy.get_meta("training_static_dummy", false)):
		_fail("Training dummy should still be marked as static-input.")
		return
	var before := Vector2(dummy.ring_pos, dummy.lane)
	dummy.velocity = Vector2(1.2, 0.45)
	dummy.angular_velocity = 0.7
	main._update_training_dummy(0.25)
	var after := Vector2(dummy.ring_pos, dummy.lane)
	if after.distance_to(before) <= 0.02:
		_fail("Training dummy velocity was anchored/cleared instead of moving after impulse.")
		return
	if dummy.velocity.length() <= 0.01:
		_fail("Training dummy velocity was cleared during static update.")
		return
	print("TRAINING_DUMMY_IMPULSE_MOVES_PROBE moved=%.3f velocity=%.3f" % [after.distance_to(before), dummy.velocity.length()])
	quit()
