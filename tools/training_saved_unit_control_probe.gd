extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _latest_training_unit_path() -> String:
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
		if String(data.get("unit_name", "")) != "4":
			continue
		var mtime := int(FileAccess.get_modified_time(path))
		if mtime >= best_time:
			best_time = mtime
			best_path = path
	return best_path


func _ensure_probe_drive_payloads(unit_bp: Dictionary) -> void:
	if not Array(unit_bp.get("slot_payloads", [])).is_empty():
		return
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var torso_node := -1
	for i in range(nodes.size()):
		if not (nodes[i] is Dictionary):
			continue
		var node: Dictionary = nodes[i]
		if String(node.get("slot", "")) == "muscle" and (bool(node.get("is_torso", false)) or String(node.get("material_class", "")).to_lower() == "torso"):
			torso_node = i
			break
	if torso_node < 0:
		return
	unit_bp["slot_payloads"] = [
		{"kind": "engine", "engine": int(unit_bp.get("engine", 0)), "internal_slot_index": 0, "torso_node": torso_node},
		{"kind": "booster", "booster": int(unit_bp.get("booster", 0)), "internal_slot_index": 1, "torso_node": torso_node},
		{"kind": "cooling", "cooling": int(unit_bp.get("cooling", 0)), "internal_slot_index": 2, "torso_node": torso_node},
	]


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var path := _latest_training_unit_path()
	var source_label := "default starter"
	if path == "":
		print("TRAINING_SAVED_UNIT_CONTROL_PROBE skipped: no saved unit 4; dedicated ball dummy is covered by training_default_ball_dummy_probe")
		quit()
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 4 JSON is invalid.")
		return
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var role_key := String(saved.get("unit_role", "hero"))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	_ensure_probe_drive_payloads(unit_bp)
	main.training_import_units = [{"role": role_key, "blueprint": unit_bp.duplicate(true)}]
	main.training_import_role_key = role_key
	main.training_import_blueprint = unit_bp.duplicate(true)
	source_label = "saved unit 4"
	main.ai_battle_seat = 1
	main.training_seat_confirmed = true
	if not main._prepare_training_battle_loadouts():
		_fail("%s training loadout was rejected: %s" % [source_label, String(main.training_import_error_note)])
		return
	if not main._configure_training_sides_for_seat():
		_fail("%s training sides could not be configured: %s" % [source_label, String(main.training_import_error_note)])
		return
	main._begin_battle(MainScene.MODE_TRAINING, true)
	var hero = main.active_units[1]["hero"]
	if not main._is_live_unit(hero):
		_fail("%s did not spawn as a controllable training hero." % source_label)
		return
	var move_speed := float(hero.stats.get("move_speed", hero.stats.get("body_move_speed", 0.0)))
	if move_speed <= 0.001 or float(hero.stats.get("turn_speed", 0.0)) <= 0.001:
		_fail("%s has no drive-derived movement/turn speed in training." % source_label)
		return
	var before_pos := Vector2(hero.ring_pos, hero.lane)
	var before_angle: float = hero.facing_angle
	hero.move_by(Vector2.RIGHT, 0.25, MainScene.RING_LENGTH)
	hero.tick(0.25, MainScene.RING_LENGTH)
	var after_right := Vector2(hero.ring_pos, hero.lane)
	hero.move_by(Vector2.UP, 0.25, MainScene.RING_LENGTH)
	hero.tick(0.25, MainScene.RING_LENGTH)
	var after_up := Vector2(hero.ring_pos, hero.lane)
	hero.velocity = Vector2.ZERO
	hero.move_by(Vector2.DOWN, 0.25, MainScene.RING_LENGTH)
	hero.tick(0.25, MainScene.RING_LENGTH)
	var after_down := Vector2(hero.ring_pos, hero.lane)
	hero.request_turn(1, 0.25)
	hero.tick(0.25, MainScene.RING_LENGTH)
	var after_pos := Vector2(hero.ring_pos, hero.lane)
	if absf(after_right.x - before_pos.x) <= 0.001:
		_fail("Training WASD-equivalent movement did not move the imported unit.")
	if absf(after_up.y - after_right.y) <= 0.001:
		_fail("Training upward movement did not change lane.")
	if absf(after_down.y - after_up.y) <= 0.001:
		_fail("Training downward movement did not change lane.")
	if absf(hero.facing_angle - before_angle) <= 0.001:
		_fail("Training Q/E-equivalent turn did not rotate the imported unit.")
	print("TRAINING_SAVED_UNIT_CONTROL_PROBE source=%s moved=%.3f lane_up=%.3f lane_down=%.3f turned=%.3f" % [source_label, after_pos.distance_to(before_pos), absf(after_up.y - after_right.y), absf(after_down.y - after_up.y), absf(hero.facing_angle - before_angle)])
	quit()
