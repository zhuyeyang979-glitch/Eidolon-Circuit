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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var path := _latest_unit2_path()
	if path == "":
		_fail("No saved unit named 2 found.")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Cannot open latest unit 2.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON invalid.")
		return
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var role_key := String(saved.get("unit_role", "hero"))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	var stats: Dictionary = main._compute_unit_stats(1, role_key, -1, unit_bp)
	var bindings: Array = Array(stats.get("runtime_module_bindings", []))
	if bindings.size() < 4:
		_fail("Unit 2 should have 4 runtime module bindings, found %d." % bindings.size())
		return
	var expected_keys := [1, 2, 3, 4]
	var seen_keys: Array = []
	for raw_binding in bindings:
		if not (raw_binding is Dictionary):
			continue
		var binding: Dictionary = raw_binding
		if String(binding.get("module_action_profile", "")) != "two_link_forward_snap":
			continue
		if not bool(binding.get("runtime_valid", false)):
			_fail("Unit 2 has invalid Two-Link binding: %s" % String(binding.get("binding_valid_note", "")))
			return
		seen_keys.append(int(binding.get("attack_key", 0)))
		var target_nodes: Array = Array(binding.get("target_nodes", []))
		if target_nodes.size() != 2:
			_fail("Unit 2 Two-Link binding target should contain exactly two nodes.")
			return
	seen_keys.sort()
	for expected in expected_keys:
		if not seen_keys.has(expected):
			_fail("Unit 2 missing Two-Link binding for attack key %d." % expected)
			return
	var payload_count := 0
	for raw_payload in Array(unit_bp.get("slot_payloads", [])):
		if raw_payload is Dictionary and String(Dictionary(raw_payload).get("kind", "")) == "module":
			payload_count += 1
	if payload_count < 4:
		_fail("Unit 2 should contain at least 4 module payloads, found %d." % payload_count)
		return
	print("UNIT2_FOUR_TWO_LINK_BINDINGS_PROBE path=%s keys=%s payloads=%d" % [ProjectSettings.globalize_path(path), str(seen_keys), payload_count])
	quit()
