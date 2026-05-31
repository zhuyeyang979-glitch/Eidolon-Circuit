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
	var torso_index := _first_torso(main)
	if torso_index < 0:
		_fail("No torso component found.")
		return
	var topology_pos := Vector2(0.48, 0.5)
	main._set_pending_canvas_part(unit_bp, "muscle", torso_index)
	var node_index := main._add_topology_node_at(main._topology_position_to_board_local(topology_pos))
	if node_index != 0:
		_fail("Expected first topology node to be 0, got %d." % node_index)
		return
	main._refresh_editor_visual_views()
	var board = main.assembly_board_view
	if board == null:
		_fail("Assembly board missing.")
		return
	if board.retained_component_items.is_empty():
		_fail("Retained component items were not created.")
		return
	var item = board.retained_component_items.get(0, null)
	if item == null:
		_fail("Retained component item 0 missing.")
		return
	var signature_before := String(item.item_signature)
	var view_signature_before := String(board.retained_view_signature)
	var invalidations_before := int(board.retained_view_invalidation_count)
	var anchor := main._topology_position_to_board_local(topology_pos)
	main._set_editor_board_zoom(1.75, anchor)
	item = board.retained_component_items.get(0, null)
	if item == null:
		_fail("Retained component item 0 disappeared after zoom.")
		return
	var signature_after := String(item.item_signature)
	var view_signature_after := String(board.retained_view_signature)
	if view_signature_before == view_signature_after:
		_fail("Retained view signature did not change after zoom.")
		return
	if signature_before == signature_after:
		_fail("Retained component signature did not change after zoom.")
		return
	if int(board.retained_view_invalidation_count) <= invalidations_before:
		_fail("Retained view transform was not invalidated after zoom.")
		return
	if not view_signature_after.contains("z:1.75"):
		_fail("Retained view signature does not include zoom: %s." % view_signature_after)
		return
	print("BOARD_ZOOM_RETAINED_NO_RESIDUE_PROBE ok invalidations=%d view=%s" % [
		int(board.retained_view_invalidation_count),
		view_signature_after,
	])
	quit()
