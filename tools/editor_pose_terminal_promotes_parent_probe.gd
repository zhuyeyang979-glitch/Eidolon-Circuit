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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var torso_index := _first_index(main, "muscle", func(part): return main._component_is_torso(part))
	var limb_index := _first_index(main, "limb_muscle", func(_part): return true)
	var terminal_index := _first_index(main, "muscle", func(part): return main._part_counts_as_terminal_weapon(part, "muscle"))
	if torso_index < 0 or limb_index < 0 or terminal_index < 0:
		_fail("Could not find torso/limb/terminal catalog parts.")
	var nodes: Array = [
		main._topology_component_node(0, "TORSO", Vector2(0.42, 0.5), "muscle", torso_index),
		main._topology_component_node(1, "LIMB", Vector2(0.58, 0.5), "limb_muscle", limb_index),
		main._topology_component_node(2, "TIP", Vector2(0.72, 0.5), "muscle", terminal_index),
	]
	var edges: Array = []
	var unit_bp := {"custom_topology": {"nodes": nodes, "edges": edges}}
	for link in [
		[0, "torso_port:0", 1, "root_joint"],
		[1, "distal", 2, "root_joint"],
	]:
		var result: Dictionary = main._topology_try_connect_sockets("hero", unit_bp, nodes, edges, int(link[0]), String(link[1]), int(link[2]), String(link[3]))
		if not bool(result.get("ok", false)):
			_fail("Failed to connect %s: %s" % [str(link), String(result.get("error", ""))])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges}
	main._topology_update_local_pose_fields("hero", unit_bp)
	var root_index := main._pose_root_for_click("hero", unit_bp, nodes, edges, 2)
	if root_index != 2:
		_fail("Clicking terminal should keep the terminal as pose root, got %d." % root_index)
	print("EDITOR_POSE_TERMINAL_INDEPENDENT_ROOT_PROBE root=%d" % root_index)
	quit()
