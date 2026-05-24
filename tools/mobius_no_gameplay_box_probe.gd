extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_nodes_by_name(root_node: Node, target_name: String, out: Array) -> void:
	if root_node.name == target_name:
		out.append(root_node)
	for child in root_node.get_children():
		_find_nodes_by_name(child, target_name, out)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.mobius_enabled = true
	main.game_state = MainScene.STATE_BATTLE
	main._refresh_mobius_surface_view()
	main._update_arena_boundary_lines()
	var arena_nodes := []
	_find_nodes_by_name(main, "ArenaPlane", arena_nodes)
	if arena_nodes.is_empty():
		_fail("ArenaPlane node should exist as an inert compatibility node for old lookups.")
	var arena_plane: CanvasItem = arena_nodes[0]
	if arena_plane.visible:
		_fail("ArenaPlane must not be visible in Möbius battle mode; it reads as a gameplay rectangle.")
	var corner_nodes := []
	_find_nodes_by_name(main, "ArenaCornerBeacon", corner_nodes)
	for raw_corner in corner_nodes:
		var corner: CanvasItem = raw_corner
		if corner.visible:
			_fail("Arena corner markers must stay hidden in Möbius battle mode.")
	if main.arena_top_boundary_line == null or main.arena_bottom_boundary_line == null:
		_fail("Boundary compatibility nodes should still exist.")
	main.camera_lane_center = MainScene.BATTLE_HALF_HEIGHT - 0.1
	main._update_arena_boundary_lines()
	if main.arena_top_boundary_line.visible or main.arena_bottom_boundary_line.visible:
		_fail("Top/bottom boundary cues must stay hidden so the local projection does not read as a box.")
	print("MOBIUS_NO_GAMEPLAY_BOX_PROBE ok boundaries_hidden=true")
	quit()
