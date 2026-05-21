extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _raw_cost(stats: Dictionary) -> int:
	return int(stats.get("raw_cost_before_maker", stats.get("raw_cost", stats.get("cost", 0))))


func _first_torso_index(main, role_key: String) -> int:
	var catalog: Array = main._catalog_for(role_key, "muscle")
	for i in range(catalog.size()):
		if main._component_is_torso(main._selected_component(role_key, "muscle", i)):
			return i
	return -1


func _first_terminal_index(main, role_key: String) -> int:
	var catalog: Array = main._catalog_for(role_key, "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component(role_key, "muscle", i)
		if not main._component_is_torso(part) and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return -1


func _custom_unit(main, role_key: String, torso_index: int, limb_index: int, terminal_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint(role_key)
	unit_bp["role"] = role_key
	unit_bp["blank_canvas"] = false
	unit_bp["name"] = "%s COST PROBE" % role_key.to_upper()
	var nodes: Array = []
	var edges: Array = []
	var torso: int = int(main._append_component_root_node(nodes, "TORSO", Vector2(0.5, 0.5), torso_index))
	var limb: int = int(main._append_directed_component_node(role_key, unit_bp, nodes, edges, torso, "LIMB", "limb_muscle", limb_index, Vector2.RIGHT, [0]))
	main._append_directed_component_node(role_key, unit_bp, nodes, edges, limb, "TIP", "muscle", terminal_index, Vector2.RIGHT)
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["slot_payloads"] = []
	return unit_bp


func _expected_node_cost(main, role_key: String, torso_index: int, limb_index: int, terminal_index: int) -> int:
	var torso_cost := int(main._selected_component(role_key, "muscle", torso_index).get("cost", 0))
	var limb_cost := int(main._selected_component(role_key, "limb_muscle", limb_index).get("cost", 0))
	var terminal_cost := int(main._selected_component(role_key, "muscle", terminal_index).get("cost", 0))
	return torso_cost + limb_cost + terminal_cost


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main._clear_editor_team()
	var blank_stats: Dictionary = main._editor_current_stats()
	var blank_summary: Dictionary = main._team_summary(1)
	if int(blank_stats.get("cost", -1)) != 0 or int(blank_summary.get("cost", -1)) != 0:
		_fail("Blank editor cost did not start at zero: unit=%s team=%s" % [str(blank_stats.get("cost", "?")), str(blank_summary.get("cost", "?"))])
	var torso_index := _first_torso_index(main, "hero")
	if torso_index < 0:
		_fail("No hero torso found.")
	var limb_index := 0
	var terminal_index := _first_terminal_index(main, "hero")
	if terminal_index < 0:
		_fail("No hero terminal weapon found.")
	var unit_bp := _custom_unit(main, "hero", torso_index, limb_index, terminal_index)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var expected_cost := _expected_node_cost(main, "hero", torso_index, limb_index, terminal_index)
	if _raw_cost(stats) != expected_cost:
		_fail("Custom topology cost should equal placed nodes only. expected=%d got raw=%d final=%d" % [expected_cost, _raw_cost(stats), int(stats.get("cost", 0))])
	var default_engine_cost := int(main._selected_component("hero", "engine", 0).get("cost", 0))
	if _raw_cost(stats) >= expected_cost + default_engine_cost:
		_fail("Default engine selection leaked into custom canvas price.")
	var with_engine := unit_bp.duplicate(true)
	with_engine["slot_payloads"] = [{"kind": "engine", "engine": 0, "torso_node": 0, "internal_slot_index": -1}]
	var engine_stats: Dictionary = main._compute_unit_stats(1, "hero", -1, with_engine)
	if _raw_cost(engine_stats) != expected_cost + default_engine_cost:
		_fail("Installed engine payload was not counted exactly once. expected=%d got raw=%d final=%d" % [expected_cost + default_engine_cost, _raw_cost(engine_stats), int(engine_stats.get("cost", 0))])
	var illegal_unit := unit_bp.duplicate(true)
	var illegal_topology: Dictionary = Dictionary(illegal_unit.get("custom_topology", {})).duplicate(true)
	illegal_topology["edges"] = [[0, 1], [0, 2]]
	illegal_unit["custom_topology"] = illegal_topology
	var illegal_stats: Dictionary = main._compute_unit_stats(1, "hero", -1, illegal_unit)
	if _raw_cost(illegal_stats) != expected_cost:
		_fail("Illegal topology should still display its real part price.")
	var puppet_unit := _custom_unit(main, "puppet", _first_torso_index(main, "puppet"), limb_index, _first_terminal_index(main, "puppet"))
	var barrier_unit := main._make_editor_blank_blueprint("barrier")
	barrier_unit["role"] = "barrier"
	main.blueprints[1] = {"hero": [unit_bp], "puppet": [puppet_unit], "barrier": [barrier_unit]}
	main.active_roster_indices[1] = {"hero": 0, "puppet": 0, "barrier": 0}
	var summary: Dictionary = main._team_summary(1)
	var sum_units := int(main._compute_unit_stats(1, "hero", 0).get("cost", 0)) + int(main._compute_unit_stats(1, "puppet", 0).get("cost", 0)) + int(main._compute_unit_stats(1, "barrier", 0).get("cost", 0))
	if int(summary.get("cost", -1)) != sum_units:
		_fail("Team total cost must equal displayed unit costs. expected=%d got=%d" % [sum_units, int(summary.get("cost", -1))])
	print("EDITOR_COST_ACCOUNTING_PROBE node_cost=%d engine_cost=%d team_cost=%d" % [expected_cost, default_engine_cost, int(summary.get("cost", 0))])
	quit()
