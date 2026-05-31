extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_topology_part(main) -> Dictionary:
	for slot_key in ["limb_muscle", "muscle"]:
		var catalog: Array = main._catalog_for("hero", slot_key)
		if not catalog.is_empty():
			return {"slot": slot_key, "index": 0}
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main._start_blank_topology()
	main._update_editor_ui(true)
	var picked := _first_topology_part(main)
	if picked.is_empty():
		_fail("No topology part available.")
		return
	var slot_key := String(picked.get("slot", ""))
	var part_index := int(picked.get("index", -1))
	main._drop_catalog_part_on_board(slot_key, part_index, Vector2(250.0, 220.0))
	var node_index := int(main.editor_last_added_topology_node_index)
	if node_index < 0:
		_fail("Drop did not create a topology node.")
		return
	var board = main.assembly_board_view
	if board == null:
		_fail("Missing assembly board view.")
		return
	if not board.retained_component_items.has(node_index):
		_fail("Drop did not create a retained component shell.")
		return
	var item = board.retained_component_items[node_index]
	if item == null or not bool(item.placeholder_mode):
		_fail("New retained component should remain placeholder on release frame.")
		return
	if int(board.retained_component_placeholder_count) <= 0:
		_fail("Placeholder counter did not increment.")
		return
	if int(board.retained_component_body_submit_count) != 0:
		_fail("Full component body was submitted during release frame.")
		return
	var flushed: int = board.flush_deferred_retained_components(1)
	if flushed != 1:
		_fail("Expected one deferred component body flush, got %d." % flushed)
		return
	if bool(item.placeholder_mode):
		_fail("Deferred body flush did not replace placeholder.")
		return
	print("RETAINED_COMPONENT_DEFERRED_FIRST_DRAW_PROBE ok node=%d placeholders=%d body_submits=%d" % [
		node_index,
		int(board.retained_component_placeholder_count),
		int(board.retained_component_body_submit_count),
	])
	quit(0)
