extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso_index(main, role_key: String) -> int:
	for i in range(main._catalog_for(role_key, "muscle").size()):
		if main._component_is_torso(main._selected_component(role_key, "muscle", i)):
			return i
	return 0


func _first_terminal_index(main, role_key: String) -> int:
	for i in range(main._catalog_for(role_key, "muscle").size()):
		var part: Dictionary = main._selected_component(role_key, "muscle", i)
		if not main._component_is_torso(part) and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return 0


func _make_probe_unit(main, role_key: String, offset: float = 0.0) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint(role_key)
	unit_bp["role"] = role_key
	unit_bp["name"] = "Probe %s" % role_key
	unit_bp["blank_canvas"] = false
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.30 + offset, 0.44), _first_torso_index(main, role_key))
	var limb_a: int = main._append_directed_component_node(role_key, unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT, [0])
	var tip: int = main._append_directed_component_node(role_key, unit_bp, nodes, edges, limb_a, "TIP", "muscle", _first_terminal_index(main, role_key), Vector2.RIGHT)
	var loose: Dictionary = main._make_topology_node(unit_bp, nodes.size(), Vector2(0.32 + offset, 0.76), "limb_muscle", 0)
	loose["label"] = "LOOSE"
	nodes.append(loose)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["slot_payloads"] = [{"kind": "module", "module": 0, "torso_node": torso}]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 0,
		"module_index": 0,
		"attack_key": 1,
		"target_kind": "limb",
		"root_index": limb_a,
		"target_nodes": [limb_a, tip],
		"target_torso_node": torso,
		"allocated_limb_momentum_by_node": {str(limb_a): 10.0, str(tip): 8.0},
		"joint_drive_allocation_by_node": {str(limb_a): 10.0, str(tip): 8.0},
	}]
	main._topology_update_local_pose_fields(role_key, unit_bp)
	main._store_entry_pose_from_topology(unit_bp)
	return unit_bp


func _node_count(unit_bp: Dictionary) -> int:
	return Array(Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])).size()


func _edge_count(unit_bp: Dictionary) -> int:
	return Array(Dictionary(unit_bp.get("custom_topology", {})).get("edges", [])).size()


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_player_id = 1
	main.editor_role_index = MainScene.ROLE_ORDER.find("puppet")
	main.blueprints[1]["puppet"] = [_make_probe_unit(main, "puppet", 0.0), main._make_editor_blank_blueprint("puppet")]
	main.blueprints[1]["puppet"][1]["name"] = "Probe puppet blank"
	main.blueprints[1]["puppet"][1]["role"] = "puppet"
	main.blueprints[1]["puppet"][1]["custom_topology"] = main._blank_free_canvas_topology()
	main.blueprints[1]["hero"] = [_make_probe_unit(main, "hero", 0.12)]
	main.editor_canvas_mode = "roster_unit"
	main.editor_unit_indices["puppet"] = 0
	main.active_roster_indices[1]["puppet"] = 0
	main.editor_roster_page = 0
	main._update_editor_ui(true)

	var first: Dictionary = main._editor_current_blueprint()
	main.editor_selected_topology_nodes = [1, 2]
	main.editor_topology_node_index = 1
	if not main._copy_selected_topology_nodes(true):
		_fail("Copy selection should succeed.")
	if Array(main.editor_topology_clipboard.get("nodes", [])).size() != 2:
		_fail("Clipboard should contain the two selected nodes.")
	if Array(main.editor_topology_clipboard.get("edges", [])).size() != 1:
		_fail("Clipboard should contain only the internal selected edge.")
	if not Array(main.editor_topology_clipboard.get("module_bindings", [])).is_empty():
		var binding: Dictionary = Array(main.editor_topology_clipboard.get("module_bindings", []))[0]
		if Array(binding.get("target_nodes", [])) != [0, 1]:
			_fail("Clipboard binding target nodes should be remapped inside the copied fragment.")

	main._select_editor_roster_overview_slot(1)
	var second: Dictionary = main._editor_current_blueprint()
	if _node_count(second) != 0:
		_fail("Second puppet page should start blank.")
	if main.editor_topology_clipboard.is_empty():
		_fail("Clipboard should survive page switching.")
	if not main._paste_topology_clipboard():
		_fail("Paste into second puppet page should succeed.")
	if _node_count(second) != 2 or _edge_count(second) != 1:
		_fail("Paste should create two nodes and one internal edge, got %d/%d." % [_node_count(second), _edge_count(second)])
	if main.editor_selected_topology_nodes.size() != 2 or main.editor_selected_topology_nodes[0] != 0:
		_fail("Pasted nodes should become the active selection.")
	if main.editor_current_stats_cache_key == "":
		_fail("Stats cache should refresh after paste.")
	if main.editor_roster_slot_buttons.size() < 2 or not main.editor_roster_slot_buttons[1].visible:
		_fail("Roster page slot 2 should be visible after selecting the second puppet.")
	if main.editor_roster_slot_buttons[1].modulate != Color(1.0, 0.86, 0.28, 1.0):
		_fail("Selected roster page should be highlighted.")

	main._select_editor_roster_overview_slot(0)
	first = main._editor_current_blueprint()
	var before_cut_nodes := _node_count(first)
	main.editor_selected_topology_nodes = [3]
	main.editor_topology_node_index = 3
	if not main._cut_selected_topology_nodes():
		_fail("Cut of a loose selected node should succeed.")
	if _node_count(first) != before_cut_nodes - 1:
		_fail("Cut should remove the selected node from the source page.")
	main._restore_editor_undo_state()
	first = main._editor_current_blueprint()
	if _node_count(first) != before_cut_nodes:
		_fail("Undo should restore the cut node.")
	main._select_editor_roster_overview_slot(1)
	var nodes_before_cut_paste := _node_count(main._editor_current_blueprint())
	if not main._paste_topology_clipboard():
		_fail("Cut fragment should paste into another page.")
	if _node_count(main._editor_current_blueprint()) != nodes_before_cut_paste + 1:
		_fail("Cut clipboard paste should add one node.")

	main.editor_selected_topology_nodes = []
	main.editor_topology_node_index = 0
	if main._copy_selected_topology_nodes(false):
		_fail("Empty selection should not copy.")

	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_unit_indices["hero"] = 0
	main.editor_canvas_mode = "roster_unit"
	var hero_before := _node_count(main._editor_current_blueprint())
	if not main._paste_topology_clipboard():
		_fail("Cross Hero/Puppet paste should be allowed on body boards.")
	if _node_count(main._editor_current_blueprint()) != hero_before + 1:
		_fail("Cross-role paste should add the copied fragment.")

	var max_unit: Dictionary = main._editor_current_blueprint()
	var max_nodes: Array = []
	for i in range(MainScene.TOPOLOGY_MAX_COMPONENT_NODES):
		max_nodes.append(main._make_topology_node(max_unit, i, Vector2(0.5, 0.5), "limb_muscle", 0))
	max_unit["custom_topology"] = {"nodes": max_nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var before_limit := _node_count(max_unit)
	if main._paste_topology_clipboard():
		_fail("Paste over the topology max node count should be rejected.")
	if _node_count(max_unit) != before_limit:
		_fail("Rejected paste should not mutate node data.")

	print("UNIT_EDITOR_CLIPBOARD_PROBE ok")
	quit(0)
