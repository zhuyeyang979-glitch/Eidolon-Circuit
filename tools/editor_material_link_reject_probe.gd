extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _limb_indices_by_material(main, role_key: String) -> Dictionary:
	var result := {}
	for i in range(main._catalog_for(role_key, "limb_muscle").size()):
		var part: Dictionary = main._selected_component(role_key, "limb_muscle", i)
		var material: String = String(main._stiffness_segment_material_family_for_part(part, "limb_muscle"))
		if not result.has(material):
			result[material] = i
	return result


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var by_material := _limb_indices_by_material(main, "hero")
	if by_material.keys().size() < 2:
		_fail("Need at least two limb-muscle materials for material reject probe.")
	var material_a := String(by_material.keys()[0])
	var material_b := String(by_material.keys()[1])
	var limb_a_index := int(by_material[material_a])
	var limb_b_index := int(by_material[material_b])
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), _first_torso(main))
	var limb_a := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", limb_a_index, Vector2.RIGHT, [0])
	var bad_limb := main._topology_component_node(nodes.size(), "BAD", main._topology_node_position(nodes[limb_a]) + Vector2(0.12, 0.0), "limb_muscle", limb_b_index)
	nodes.append(bad_limb)
	var bad_edges := edges.duplicate(true)
	bad_edges.append(main._topology_make_socket_edge(limb_a, "distal", nodes.size() - 1, "root_joint"))
	var bad_error := main._topology_material_edge_error("hero", unit_bp, nodes, edges, limb_a, nodes.size() - 1)
	if bad_error == "":
		_fail("Different material should be rejected in the same direct limb group.")
	var same_limb := main._topology_component_node(nodes.size(), "SAME", main._topology_node_position(nodes[limb_a]) + Vector2(0.12, 0.0), "limb_muscle", limb_a_index)
	nodes.append(same_limb)
	var same_error := main._topology_material_edge_error("hero", unit_bp, nodes, edges, limb_a, nodes.size() - 1)
	if same_error != "":
		_fail("Same material should remain legal, got %s." % same_error)
	print("EDITOR_MATERIAL_LINK_REJECT_PROBE good=%s rejected=%s edges=%d" % [material_a, material_b, edges.size()])
	quit()
