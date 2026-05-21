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
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (parsed is Dictionary):
			continue
		if String(Dictionary(parsed).get("unit_name", "")) != "2":
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
		return
	var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (saved is Dictionary):
		_fail("Unit 2 save file is invalid.")
		return
	var restored: Dictionary = main._json_restore_value(Dictionary(saved))
	var role_key := String(restored.get("unit_role", "hero"))
	var unit_bp: Dictionary = Dictionary(restored.get("blueprint", {})).duplicate(true)
	main.training_import_units = [{"role": role_key, "blueprint": unit_bp.duplicate(true)}]
	main.training_import_role_key = role_key
	main.training_import_blueprint = unit_bp.duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	var hero = Dictionary(main.active_units.get(1, {})).get("hero", null)
	if hero == null:
		_fail("Unit 2 did not spawn a controllable training hero.")
		return
	var bindings: Array = Array(hero.stats.get("runtime_module_bindings", []))
	if bindings.is_empty():
		_fail("Unit 2 has no runtime module bindings.")
		return
	var binding: Dictionary = Dictionary(bindings[0])
	var first_node := int(Array(binding.get("target_nodes", []))[0])
	var before: Dictionary = hero._runtime_segment_source_by_node(first_node)
	var before_b: Vector2 = hero._runtime_local_vector(before.get("b_local", Vector2.ZERO))
	var event: Dictionary = hero.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Training module action did not start: %s" % String(hero.get_meta("last_module_gate_reason", "")))
		return
	hero._tick_runtime_module_actions(10.0)
	var after: Dictionary = hero._runtime_segment_source_by_node(first_node)
	var after_b: Vector2 = hero._runtime_local_vector(after.get("b_local", Vector2.ZERO))
	if after_b.distance_to(before_b) < 0.05:
		_fail("Training module action did not persist its end pose.")
		return
	print("TRAINING_MODULE_POSE_PERSIST_PROBE path=%s" % ProjectSettings.globalize_path(path))
	quit()
