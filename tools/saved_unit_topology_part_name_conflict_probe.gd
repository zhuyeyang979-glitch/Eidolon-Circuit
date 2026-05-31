extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var torso_name := "PARACHUTE CLAIM PLATING"
	var stale_name := "FORTRESS STATIC CATHEDRAL"
	var torso_index := main._component_index_by_exact_name("hero", "muscle", torso_name)
	var stale_index := main._component_index_by_exact_name("hero", "muscle", stale_name)
	if torso_index < 0 or stale_index < 0:
		_fail("Probe catalog parts missing: torso=%d stale=%d." % [torso_index, stale_index])
		return
	var node := {
		"id": 0,
		"label": "CORE",
		"slot": "muscle",
		"part_index": stale_index,
		"part_name": stale_name,
		"name": torso_name,
		"component_name": torso_name,
		"is_torso": true,
		"material_class": "torso",
		"catalog_role": "torso",
		"part_category": "torso",
		"pos": Vector2(0.5, 0.5),
	}
	var unit_bp := {
		"role": "hero",
		"unit_name": "Topology Part Name Conflict Probe",
		"blank_canvas": false,
		"custom_topology": {
			"nodes": [node],
			"edges": [],
			"edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION,
		},
	}
	var resolved := main._topology_node_resolved_part_index("hero", node, unit_bp)
	if resolved != torso_index:
		_fail("Conflicting node should resolve to torso part index %d, got %d." % [torso_index, resolved])
		return
	var resolved_part: Dictionary = main._topology_node_part("hero", node, unit_bp)
	if String(resolved_part.get("name", "")) != torso_name or not main._component_is_torso(resolved_part):
		_fail("Conflicting node resolved to wrong part: %s." % String(resolved_part.get("name", "")))
		return
	var note := main._training_blueprint_illegal_note(1, "hero", unit_bp)
	if note.find("torso/core") >= 0:
		_fail("Torso identity conflict still reports missing torso: %s" % note)
		return
	main._stamp_saved_blueprint_part_names("hero", unit_bp)
	var stamped_nodes: Array = Array(Dictionary(unit_bp.get("custom_topology", {})).get("nodes", []))
	if stamped_nodes.is_empty() or not (stamped_nodes[0] is Dictionary):
		_fail("Stamped topology lost the probe node.")
		return
	var stamped: Dictionary = stamped_nodes[0]
	if int(stamped.get("part_index", -1)) != torso_index:
		_fail("Stamped node kept stale part_index: %s." % String(stamped.get("part_index", "")))
		return
	if String(stamped.get("part_name", "")) != torso_name or String(stamped.get("component_name", "")) != torso_name:
		_fail("Stamped node did not repair names: part=%s component=%s." % [String(stamped.get("part_name", "")), String(stamped.get("component_name", ""))])
		return
	print("SAVED_UNIT_TOPOLOGY_PART_NAME_CONFLICT_PROBE ok note=%s" % note)
	quit()
