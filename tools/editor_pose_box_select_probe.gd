extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_terminal_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_torso(part) and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	main.editor_board_tool = "pose"
	var unit_bp: Dictionary = main._editor_current_blueprint()
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), _first_torso_index(main))
	var limb_a := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT, [0])
	var limb_b := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	var tip := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_b, "TIP", "muscle", _first_terminal_index(main), Vector2.RIGHT)
	var second := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "OTHER", "limb_muscle", 0, Vector2.UP, [1])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var root_index := main._pose_root_for_selection("hero", unit_bp, nodes, edges, [limb_b, tip])
	if root_index != limb_b:
		_fail("Box selection should choose the nearest selected limb as root; got %d." % root_index)
	if not main._pose_selection_is_single_downstream_chain("hero", unit_bp, nodes, edges, root_index, [limb_b, tip]):
		_fail("Single downstream selection was rejected.")
	var proximal_root := main._pose_root_for_selection("hero", unit_bp, nodes, edges, [limb_a, limb_b, tip])
	if proximal_root != limb_a:
		_fail("Whole limb selection should choose proximal limb A as root; got %d." % proximal_root)
	if not main._pose_selection_is_single_downstream_chain("hero", unit_bp, nodes, edges, proximal_root, [limb_a, limb_b, tip]):
		_fail("Whole downstream chain selection was rejected.")
	if main._pose_selection_is_single_downstream_chain("hero", unit_bp, nodes, edges, proximal_root, [limb_a, second]):
		_fail("Pose selection accepted nodes from two different limbs.")
	print("EDITOR_POSE_BOX_SELECT_PROBE ok")
	quit()
