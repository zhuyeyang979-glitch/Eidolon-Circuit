extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect_array(label: String, actual: Array, expected: Array) -> void:
	if actual.size() != expected.size():
		_fail("%s size mismatch: expected %s got %s" % [label, str(expected), str(actual)])
	for i in range(expected.size()):
		if int(actual[i]) != int(expected[i]):
			_fail("%s mismatch at %d: expected %s got %s" % [label, i, str(expected), str(actual)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var profiles := {
		"XS": [2, 1, 1],
		"S": [3, 2, 2, 1],
		"M": [4, 3, 3, 2, 2],
		"L": [5, 4, 4, 3, 3, 2],
		"XL": [5, 5, 4, 4, 3, 3, 2, 2],
	}
	for tier in profiles.keys():
		var torso := {"name": "%s TEST TORSO" % tier, "size_tier": tier, "size_class": tier, "is_torso": true, "torso_slots": Array(profiles[tier]).size()}
		_expect_array("auto profile %s" % tier, main._torso_internal_slot_size_ranks(torso), profiles[tier])
	var explicit := {"name": "EXPLICIT TORSO", "size_tier": "M", "is_torso": true, "torso_slots": 4, "internal_slot_sizes": ["XL", "S"]}
	_expect_array("explicit profile repeats tail", main._torso_internal_slot_size_ranks(explicit), [5, 2, 2, 2, 2])
	var xs_torso := {"name": "XS SOCKET TEST", "size_tier": "XS", "is_torso": true, "torso_slots": 3}
	var payload := {"kind": "engine", "engine": 0}
	var medium_engine := {"name": "M ENGINE", "slot_volume_tier": "M", "mass": 4, "power": 40}
	var xs_engine := {"name": "XS ENGINE", "slot_volume_tier": "XS", "mass": 1, "power": 8}
	var xs_cooler := {"name": "XS COOLER", "mass": 1, "cooling": 8, "heat_capacity": 4}
	var s_cooler := {"name": "S COOLER", "mass": 3, "cooling": 12, "heat_capacity": 8}
	if main._find_internal_slot_for_payload({"slot_payloads": []}, 0, xs_torso, "engine", medium_engine, payload, 1) != -1:
		_fail("Medium engine fit into XS-limited slot.")
	if main._find_internal_slot_for_payload({"slot_payloads": []}, 0, xs_torso, "engine", xs_engine, payload, 1) != 1:
		_fail("XS engine did not fit into requested XS slot.")
	if main._find_internal_slot_for_payload({"slot_payloads": []}, 0, xs_torso, "engine", medium_engine, payload, -1) != -1:
		_fail("Medium engine should not fit any XS torso slot profile.")
	if int(main._payload_slot_volume_rank("cooling", xs_cooler, {"kind": "cooling"}, "cooling")) != 1:
		_fail("Low-mass low-output cooler should infer XS slot volume.")
	if int(main._payload_slot_volume_rank("cooling", s_cooler, {"kind": "cooling"}, "cooling")) != 2:
		_fail("Small cooler should infer S slot volume.")
	if main._find_internal_slot_for_payload({"slot_payloads": []}, 0, xs_torso, "cooling", xs_cooler, {"kind": "cooling", "cooling": 0}, 1) != 1:
		_fail("XS cooler did not fit into requested XS slot.")
	if main._find_internal_slot_for_payload({"slot_payloads": []}, 0, xs_torso, "cooling", s_cooler, {"kind": "cooling", "cooling": 0}, 1) != -1:
		_fail("S cooler should not fit into requested XS slot.")
	var xs_torso_index := -1
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part) and main._torso_size_rank_for_slots(part) == 1:
			xs_torso_index = i
			break
	if xs_torso_index < 0:
		_fail("No XS torso found for UI installation path.")
	var vent_index := -1
	for i in range(main._catalog_for("hero", "cooling").size()):
		var cooler: Dictionary = main._selected_component("hero", "cooling", i)
		if String(cooler.get("name", "")).to_upper().contains("VENT SHEET") or int(main._payload_slot_volume_rank("cooling", cooler, {"kind": "cooling", "cooling": i}, "cooling")) == 1:
			vent_index = i
			break
	if vent_index < 0:
		_fail("No XS cooling plugin found for UI installation path.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var torso_node := main._append_component_root_node(nodes, "XS CORE", Vector2(0.5, 0.5), xs_torso_index)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_canvas_mode = "blank"
	main.editor_open_torso_node_index = torso_node
	var vent_part: Dictionary = main._selected_component("hero", "cooling", vent_index)
	main._add_torso_payload_component("cooling", vent_index, vent_part, 1)
	var payloads: Array = unit_bp.get("slot_payloads", [])
	if payloads.size() != 1:
		_fail("XS cooler install path did not add payload: %s" % main.editor_summary_label.text)
	if int(Dictionary(payloads[0]).get("internal_slot_index", -1)) != 1:
		_fail("XS cooler did not install into requested XS slot through UI path.")
	print("INTERNAL_SLOT_SIZE_PROBE profiles=%d explicit=%s" % [profiles.size(), str(main._torso_internal_slot_size_ranks(explicit))])
	quit()
