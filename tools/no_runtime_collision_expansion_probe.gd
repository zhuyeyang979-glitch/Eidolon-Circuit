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
	main.training_import_units = [{"role": role_key, "blueprint": bp.duplicate(true)}]
	main.training_import_role_key = role_key
	main.training_import_blueprint = bp.duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	var hero = main.active_units[1]["hero"]
	if not main._is_live_unit(hero):
		_fail("Training hero missing.")
	var segments: Array = Array(hero.stats.get("runtime_topology_segments", []))
	var colliders: Array = hero.part_colliders()
	if segments.is_empty() or colliders.is_empty():
		_fail("Runtime topology segments/colliders missing.")
	for raw_collider in colliders:
		if raw_collider is Dictionary and String(Dictionary(raw_collider).get("part_kind", "")) != "torso":
			_fail("Idle saved-unit limbs should not expose independent colliders.")
	for raw_segment in segments:
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = raw_segment
		var node_index := int(segment.get("node_index", -999))
		var part_kind := String(segment.get("part_kind", ""))
		if part_kind != "torso":
			continue
		var found := false
		for raw_collider in colliders:
			if not (raw_collider is Dictionary):
				continue
			var collider: Dictionary = raw_collider
			if int(collider.get("node_index", -998)) != node_index or String(collider.get("part_kind", "")) != part_kind:
				continue
			found = true
			if String(collider.get("shape", "")) != "polygon":
				_fail("Runtime segment was not converted to exact polygon collider.")
			if not collider.has("polygon") or Array(collider.get("polygon", [])).size() < 3:
				_fail("Runtime polygon collider is missing polygon points.")
			if float(collider.get("radius", 1.0)) != 0.0:
				_fail("Runtime polygon collider kept an expanded radius.")
			break
		if not found:
			_fail("No collider found for runtime segment node %d (%s)." % [node_index, part_kind])
	var bindings: Array = Array(hero.stats.get("runtime_module_bindings", []))
	if bindings.is_empty():
		_fail("Saved unit 2 has no runtime module binding to test active limb colliders.")
	var event: Dictionary = hero.begin_runtime_module_action("normal", Dictionary(bindings[0]), Vector2.RIGHT)
	if event.is_empty():
		_fail("Could not start runtime module action for active collider check.")
	var active_nodes := {}
	for raw_node in Array(Dictionary(bindings[0]).get("target_nodes", [])):
		active_nodes[int(raw_node)] = true
	var active_colliders: Array = hero.part_colliders()
	for raw_node in active_nodes.keys():
		var node_found := false
		for raw_collider in active_colliders:
			if raw_collider is Dictionary and int(Dictionary(raw_collider).get("node_index", -999)) == int(raw_node):
				node_found = true
				if float(Dictionary(raw_collider).get("radius", 1.0)) != 0.0:
					_fail("Active runtime collider kept an expanded radius.")
				break
		if not node_found:
			_fail("Active runtime target node %d did not expose a collider during action." % int(raw_node))
	print("NO_RUNTIME_COLLISION_EXPANSION_PROBE idle=%d active=%d" % [colliders.size(), active_colliders.size()])
	quit()
