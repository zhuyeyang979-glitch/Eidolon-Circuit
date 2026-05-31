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


func _highlight_state(main, node_index: int) -> String:
	var highlights: Dictionary = main.assembly_board_view.board_snapshot.get("material_highlights", {})
	return String(Dictionary(highlights.get(str(node_index), {})).get("state", ""))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var by_material := _limb_indices_by_material(main, "hero")
	if by_material.keys().size() < 2:
		_fail("Need at least two limb-muscle materials for highlight probe.")
	var material_a := String(by_material.keys()[0])
	var material_b := String(by_material.keys()[1])
	var limb_a_index := int(by_material[material_a])
	var limb_b_index := int(by_material[material_b])
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), _first_torso(main))
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LINK", "limb_muscle", limb_a_index, Vector2.RIGHT, [0])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main.editor_hover_slot_key = "limb_muscle"
	main.editor_hover_part_index = limb_a_index
	main._refresh_editor_visual_views()
	var same_state := _highlight_state(main, limb)
	if not same_state in ["legal_socket", "same_limb"]:
		_fail("Same-material hover should mark direct limb endpoint legal, got %s." % same_state)
	main.editor_hover_part_index = limb_b_index
	main._refresh_editor_visual_views()
	var diff_state := _highlight_state(main, limb)
	if not diff_state in ["illegal_material", "illegal_group"]:
		_fail("Different-material hover should mark direct limb endpoint illegal, got %s." % diff_state)
	print("EDITOR_MATERIAL_HIGHLIGHT_PROBE same=%s diff=%s same_state=%s diff_state=%s" % [material_a, material_b, same_state, diff_state])
	quit()
