extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


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


func _first_torso_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			return i
	return -1


func _first_limb_index(main) -> int:
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		return i
	return -1


func _first_terminal_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_torso(part) and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return -1


func _fixture_blueprint(main) -> Dictionary:
	var torso_index := _first_torso_index(main)
	var limb_index := _first_limb_index(main)
	var terminal_index := _first_terminal_index(main)
	if min(torso_index, limb_index, terminal_index) < 0:
		_fail("Could not build runtime geometry fixture from catalog.")
	var bp: Dictionary = main._make_editor_blank_blueprint("hero")
	bp["role"] = "hero"
	bp["unit_name"] = "RuntimeGeometryFixture"
	bp["blank_canvas"] = false
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.44, 0.52), torso_index)
	var limb: int = main._append_directed_component_node("hero", bp, nodes, edges, torso, "LINK", "limb_muscle", limb_index, Vector2.RIGHT, [0])
	main._append_directed_component_node("hero", bp, nodes, edges, limb, "TIP", "muscle", terminal_index, Vector2.RIGHT)
	bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", bp)
	return bp


func _blueprint_from_saved_or_fixture(main) -> Dictionary:
	var path := _latest_unit2_path()
	if path == "":
		return {"role_key": "hero", "blueprint": _fixture_blueprint(main), "source": "fixture"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"role_key": "hero", "blueprint": _fixture_blueprint(main), "source": "fixture"}
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON is invalid.")
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var role_key := String(saved.get("unit_role", "hero"))
	var bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	return {"role_key": role_key, "blueprint": bp, "source": path}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var resolved := _blueprint_from_saved_or_fixture(main)
	var role_key := String(resolved.get("role_key", "hero"))
	var bp: Dictionary = Dictionary(resolved.get("blueprint", {})).duplicate(true)
	var source := String(resolved.get("source", "fixture"))
	var stats: Dictionary = main._compute_unit_stats(1, role_key, 0, bp)
	var stat_segments: Array = Array(stats.get("runtime_topology_segments", []))
	var stat_torso: Dictionary = {}
	for raw_segment in stat_segments:
		if raw_segment is Dictionary and String(Dictionary(raw_segment).get("part_kind", "")) == "torso":
			stat_torso = Dictionary(raw_segment)
			break
	if stat_torso.is_empty() or String(stat_torso.get("shape", "")) != "polygon" or Array(stat_torso.get("polygon_local", [])).size() < 3:
		_fail("Saved unit stats did not preserve a polygon TeamEdit torso.")
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "RuntimeGeometryIdentity", "owner_id": 1, "role": role_key, "stats": stats})
	fighter.deploy(5.0, -0.25)
	var runtime_segments: Array = Array(fighter.stats.get("runtime_topology_segments", []))
	if runtime_segments.size() != stat_segments.size():
		_fail("Runtime segment count differs from TeamEdit stats: %d vs %d" % [runtime_segments.size(), stat_segments.size()])
	var colliders: Array = fighter.part_colliders()
	var collider_torso: Dictionary = {}
	for raw_collider in colliders:
		if raw_collider is Dictionary and String(Dictionary(raw_collider).get("part_kind", "")) == "torso":
			collider_torso = Dictionary(raw_collider)
			break
	if collider_torso.is_empty() or String(collider_torso.get("shape", "")) != "polygon" or Array(collider_torso.get("polygon", [])).size() != Array(stat_torso.get("polygon_local", [])).size():
		_fail("Runtime torso collider is not the same polygon topology as TeamEdit.")
	print("RUNTIME_GEOMETRY_IDENTITY_PROBE source=%s segments=%d torso_points=%d" % [source, runtime_segments.size(), Array(collider_torso.get("polygon", [])).size()])
	quit()
