extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
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
		_fail("Cannot open unit 2.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON invalid.")
		return
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	var role_key := String(saved.get("unit_role", "hero"))
	var stats: Dictionary = main._compute_unit_stats(1, role_key, -1, unit_bp)
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Fallback Probe", "owner_id": 1, "role": role_key, "stats": stats})
	fighter.deploy(4.0, 0.0)
	if not fighter._has_runtime_topology():
		_fail("Fighter did not receive runtime topology.")
		return
	for legacy_name in ["Shell", "TopologyLine", "MuscleA", "MuscleB", "JointA", "JointB", "SpecialCore", "CoreProceduralArt"]:
		if fighter.find_child(legacy_name, true, false) != null:
			_fail("Legacy visual node still exists for a saved TeamEdit unit: %s." % legacy_name)
			return
	var colliders: Array = fighter.part_colliders()
	if colliders.is_empty():
		_fail("Runtime fighter produced no topology colliders.")
		return
	for raw_collider in colliders:
		if raw_collider is Dictionary and not bool(Dictionary(raw_collider).get("runtime_topology", false)):
			_fail("Non-runtime collider leaked into saved TeamEdit unit.")
			return
	print("FIGHTER_NO_LEGACY_FALLBACK_PROBE colliders=%d" % colliders.size())
	quit()
