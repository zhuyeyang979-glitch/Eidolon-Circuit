extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part_index(main, slot_key: String, name_fragment: String) -> int:
	for i in range(main._catalog_for("hero", slot_key).size()):
		var part: Dictionary = main._selected_component("hero", slot_key, i)
		if String(part.get("name", "")).findn(name_fragment) >= 0:
			return i
	return -1


func _module_index(main, profile: String) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == profile:
			return i
	return -1


func _build_duelist_unit(main) -> Dictionary:
	var soul_index := _part_index(main, "special", "FIRST EDGE ECHO")
	var torso_index := _part_index(main, "muscle", "HUMANOVA DUEL CORE")
	var limb_index := _part_index(main, "limb_muscle", "HUMANOVA FOREARM MYOMER")
	var rapier_index := _part_index(main, "muscle", "HUMANOVA NEEDLE RAPIER")
	var katana_index := _part_index(main, "muscle", "WAKIZASHI KATANA")
	var lance_index := _part_index(main, "muscle", "SHORT JOUSTING LANCE")
	var module_a := _module_index(main, "blade_arc_return")
	var module_b := _module_index(main, "katana_quickdraw")
	var module_c := _module_index(main, "pierce_rail_3m")
	if min(soul_index, torso_index, limb_index, rapier_index, katana_index, lance_index, module_a, module_b, module_c) < 0:
		_fail("Missing catalog anchors for duelist oath activation.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "DUEL CORE", Vector2(0.42, 0.5), torso_index)
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", limb_index, Vector2(1, -0.45), [module_a])
	var weapon_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "RAPIER", "muscle", rapier_index, Vector2(1, -0.45))
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "B", "limb_muscle", limb_index, Vector2(1, 0.0), [module_b])
	var weapon_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_b, "KATANA", "muscle", katana_index, Vector2(1, 0.0))
	var limb_c: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "C", "limb_muscle", limb_index, Vector2(1, 0.45), [module_c])
	var weapon_c: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_c, "LANCE", "muscle", lance_index, Vector2(1, 0.45))
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["special"] = soul_index
	unit_bp["slot_payloads"] = [
		{"kind": "special", "special": soul_index, "torso_node": torso},
		{"kind": "module", "module": module_a, "torso_node": torso},
		{"kind": "module", "module": module_b, "torso_node": torso},
		{"kind": "module", "module": module_c, "torso_node": torso},
	]
	unit_bp["module_bindings"] = [
		{"software_slot_index": 1, "module_index": module_a, "attack_key": 1, "target_kind": "limb", "target_nodes": [limb_a, weapon_a], "target_torso_node": torso},
		{"software_slot_index": 2, "module_index": module_b, "attack_key": 2, "target_kind": "limb", "target_nodes": [limb_b, weapon_b], "target_torso_node": torso},
		{"software_slot_index": 3, "module_index": module_c, "attack_key": 3, "target_kind": "limb", "target_nodes": [limb_c, weapon_c], "target_torso_node": torso},
	]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit_bp := _build_duelist_unit(main)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	if String(stats.get("soul_archetype", "")) != "duelist_oath":
		_fail("Computed stats did not keep the duelist soul archetype.")
	if not bool(stats.get("soul_oath_active", false)):
		_fail("Valid duelist unit should activate oath, reason=%s stats=%s" % [String(stats.get("soul_oath_reason", "")), str({"mass": stats.get("mass"), "radius": stats.get("radius")})])
	if float(stats.get("soul_echo_window", 0.0)) <= 0.0 or float(stats.get("soul_echo_recovery_mult", 1.0)) >= 1.0:
		_fail("Active oath should publish runtime echo timing fields.")
	print("SOUL_OATH_ACTIVATION_PROBE ok")
	quit()
