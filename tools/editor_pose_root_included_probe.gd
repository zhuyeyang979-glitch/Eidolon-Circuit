extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_index(main, slot_key: String, predicate: Callable) -> int:
	var catalog: Array = main._catalog_for("hero", slot_key)
	for i in range(catalog.size()):
		if bool(predicate.call(Dictionary(catalog[i]))):
			return i
	return -1


func _make_chain(main) -> Dictionary:
	var torso_index := _first_index(main, "muscle", func(part): return main._component_is_torso(part))
	var limb_index := _first_index(main, "limb_muscle", func(_part): return true)
	var terminal_index := _first_index(main, "muscle", func(part): return main._part_counts_as_terminal_weapon(part, "muscle"))
	if torso_index < 0 or limb_index < 0 or terminal_index < 0:
		_fail("Could not find torso/limb/terminal catalog parts.")
	var nodes: Array = [
		main._topology_component_node(0, "TORSO", Vector2(0.42, 0.5), "muscle", torso_index),
		main._topology_component_node(1, "LIMB A", Vector2(0.54, 0.5), "limb_muscle", limb_index),
		main._topology_component_node(2, "LIMB B", Vector2(0.66, 0.5), "limb_muscle", limb_index),
		main._topology_component_node(3, "TIP", Vector2(0.78, 0.5), "muscle", terminal_index),
	]
	var edges: Array = []
	var unit_bp := {"custom_topology": {"nodes": nodes, "edges": edges}}
	for link in [
		[0, "torso_port:0", 1, "root_joint"],
		[1, "distal", 2, "root_joint"],
		[2, "distal", 3, "root_joint"],
	]:
		var result: Dictionary = main._topology_try_connect_sockets("hero", unit_bp, nodes, edges, int(link[0]), String(link[1]), int(link[2]), String(link[3]))
		if not bool(result.get("ok", false)):
			_fail("Failed to connect %s: %s" % [str(link), String(result.get("error", ""))])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges}
	main._snap_all_topology_edges("hero", unit_bp)
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit_bp := _make_chain(main)
	var topology: Dictionary = unit_bp["custom_topology"]
	var nodes: Array = topology["nodes"]
	var downstream: Array = main._topology_downstream_node_indices("hero", unit_bp, nodes, topology["edges"], 1)
	if not downstream.has(1) or not downstream.has(2) or not downstream.has(3):
		_fail("Downstream list must include root and distal chain, got %s." % str(downstream))
	var root_before: Vector2 = main._topology_node_position(Dictionary(nodes[1]))
	var distal_before: Vector2 = main._topology_node_position(Dictionary(nodes[3]))
	var root_node: Dictionary = nodes[1]
	root_node["local_angle"] = float(root_node.get("local_angle", 0.0)) + PI * 0.48
	nodes[1] = root_node
	topology["nodes"] = nodes
	unit_bp["custom_topology"] = topology
	main._topology_apply_local_fk("hero", unit_bp, 1)
	nodes = Dictionary(unit_bp["custom_topology"])["nodes"]
	var root_after: Vector2 = main._topology_node_position(Dictionary(nodes[1]))
	var distal_after: Vector2 = main._topology_node_position(Dictionary(nodes[3]))
	if root_after.distance_to(root_before) < 0.005:
		_fail("Root limb did not move when its own local_angle changed.")
	if distal_after.distance_to(distal_before) < 0.005:
		_fail("Distal chain did not follow root limb rotation.")
	print("EDITOR_POSE_ROOT_INCLUDED_PROBE root_delta=%.4f distal_delta=%.4f" % [root_after.distance_to(root_before), distal_after.distance_to(distal_before)])
	quit()
