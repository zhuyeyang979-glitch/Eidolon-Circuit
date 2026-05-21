extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _place(main, unit_bp: Dictionary, slot_key: String, part_index: int, pos: Vector2) -> int:
	main._set_pending_canvas_part(unit_bp, slot_key, part_index)
	return int(main._add_topology_node_at(pos))


func _edge_count(unit_bp: Dictionary) -> int:
	return Array(Dictionary(unit_bp.get("custom_topology", {})).get("edges", [])).size()


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var joint_index := _place(main, unit_bp, "joint", 0, Vector2(310.0, 250.0))
	var right_muscle := _place(main, unit_bp, "limb_muscle", 0, Vector2(362.0, 250.0))
	if not main._try_magnetic_link_for_node(unit_bp, right_muscle):
		_fail("Right muscle did not link.")
	var left_muscle := _place(main, unit_bp, "limb_muscle", 0, Vector2(258.0, 250.0))
	if not main._try_magnetic_link_for_node(unit_bp, left_muscle):
		_fail("Left muscle did not link.")
	if _edge_count(unit_bp) != 2:
		_fail("Expected two links before unlink, got %d." % _edge_count(unit_bp))
	if not main._unlink_joint_edges(unit_bp, joint_index, right_muscle):
		_fail("Preferred-neighbor unlink failed.")
	unit_bp = main._editor_current_blueprint()
	if _edge_count(unit_bp) != 1:
		_fail("Expected one link after preferred unlink, got %d." % _edge_count(unit_bp))
	main._restore_editor_undo_state()
	unit_bp = main._editor_current_blueprint()
	if _edge_count(unit_bp) != 2:
		_fail("Undo did not restore two links; got %d." % _edge_count(unit_bp))
	if not main._unlink_joint_edges(unit_bp, joint_index):
		_fail("Whole-joint unlink failed.")
	unit_bp = main._editor_current_blueprint()
	if _edge_count(unit_bp) != 0:
		_fail("Expected zero links after whole-joint unlink, got %d." % _edge_count(unit_bp))
	print("EDITOR_JOINT_UNLINK_PROBE edges_after=%d undo_stack=%d" % [_edge_count(unit_bp), main.editor_undo_stack.size()])
	quit()
