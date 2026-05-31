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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso_part := _first_torso(main)
	if torso_part < 0:
		_fail("No torso catalog part.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_part)
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LIMB", "limb_muscle", 0, Vector2.RIGHT, [0])
	var torso_pos: Vector2 = main._topology_node_position(nodes[torso])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var desired_torso := torso_pos + Vector2(0.2, -0.2)
	var snapped_torso: Vector2 = main._snap_position_to_fixed_connection("hero", unit_bp, nodes, edges, torso, desired_torso)
	if snapped_torso.distance_to(torso_pos) > 0.00001:
		_fail("Child/socket snap attempted to pull the torso root.")
	var limb_before: Vector2 = main._topology_node_position(nodes[limb])
	main._move_custom_node_to(unit_bp, limb, main._topology_position_to_board_local(limb_before + Vector2(0.15, 0.0)))
	var moved_nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	if main._topology_node_position(moved_nodes[torso]).distance_to(torso_pos) > 0.00001:
		_fail("Low-level child move pulled the torso root.")
	print("CHILD_SNAP_DOES_NOT_PULL_TORSO_PROBE ok")
	quit()
