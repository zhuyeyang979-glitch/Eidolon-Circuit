extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expected_plugin_capacity(main, part: Dictionary) -> int:
	var cap := int(part.get("torso_slots", 0))
	if cap <= 0:
		cap = int(part.get("engine_slots", 0)) + int(part.get("cooling_slots", 0)) + int(part.get("booster_slots", 0)) + int(part.get("spare_weapon_slots", 0))
	cap = maxi(cap, main._torso_baseline_slot_capacity(part, "plugin"))
	return clampi(cap + 1, 1, 12)


func _expected_software_capacity(main, part: Dictionary) -> int:
	var cap := int(part.get("module_slots", 0))
	cap = maxi(cap, main._torso_baseline_slot_capacity(part, "software"))
	if main._component_is_brain_torso(part):
		cap = maxi(cap, 8)
	return clampi(cap + 1, 1, 12)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var torso_count := 0
	var first_torso_index := -1
	for i in range(MainScene.COMMON_CATALOG["muscle"].size()):
		var part: Dictionary = MainScene.COMMON_CATALOG["muscle"][i]
		if not main._component_is_torso(part):
			continue
		torso_count += 1
		if first_torso_index < 0:
			first_torso_index = i
		var expected_plugin := _expected_plugin_capacity(main, part)
		var expected_software := _expected_software_capacity(main, part)
		var actual_plugin := main._torso_plugin_capacity_for_part(part)
		var actual_software := main._torso_software_capacity_for_part(part)
		if actual_plugin != expected_plugin:
			_fail("%s plugin capacity expected %d got %d." % [String(part.get("name", "torso")), expected_plugin, actual_plugin])
		if actual_software != expected_software:
			_fail("%s software capacity expected %d got %d." % [String(part.get("name", "torso")), expected_software, actual_software])
	if torso_count <= 0 or first_torso_index < 0:
		_fail("No torso parts found.")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, "muscle", first_torso_index)
	var torso_node := main._add_topology_node_at(Vector2(480.0, 300.0))
	if torso_node < 0:
		_fail("Could not place torso for detail capacity check.")
	main._open_editor_torso_detail(torso_node)
	var torso_part: Dictionary = MainScene.COMMON_CATALOG["muscle"][first_torso_index]
	if main.editor_torso_detail_view.plugin_capacity != main._torso_plugin_capacity_for_part(torso_part):
		_fail("Torso detail plugin capacity does not use normalized helper.")
	if main.editor_torso_detail_view.software_capacity != main._torso_software_capacity_for_part(torso_part):
		_fail("Torso detail software capacity does not use normalized helper.")
	print("TORSO_SLOT_CAPACITY_PLUS_ONE_PROBE ok torsos=%d" % torso_count)
	quit()
