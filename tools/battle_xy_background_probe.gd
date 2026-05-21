extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_visible_world_art(main) -> Dictionary:
	for raw_entry in main.world_background_art_nodes:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var node: Node2D = entry.get("node", null)
		if node != null and is_instance_valid(node) and node.visible:
			return entry
	return {}


func _visible_grid_count(main) -> int:
	var count := 0
	for raw_line in main.world_coordinate_grid_lines:
		if raw_line is Line2D:
			var line := raw_line as Line2D
			if line.visible:
				count += 1
	return count


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.camera_center = 3.0
	main.camera_lane_center = -1.0
	main._update_parallax_background()
	if _visible_grid_count(main) > 0:
		_fail("Visible coordinate grid lines remain in battle background.")
		return
	if main.world_background_art_nodes.is_empty():
		_fail("World-bound background art was not built.")
		return
	var entry := _first_visible_world_art(main)
	if entry.is_empty():
		_fail("No visible world-bound background art near camera.")
		return
	var node: Node2D = entry["node"]
	var start_position := node.position
	var scale := main._battle_world_to_screen_scale()
	main.camera_center += 0.37
	main._update_parallax_background()
	var after_x := node.position
	var x_shift := after_x.x - start_position.x
	if absf(absf(x_shift) - 0.37 * scale) > 1.8:
		_fail("World art X shift is not tied to world scale: %.3f vs %.3f." % [x_shift, -0.37 * scale])
		return
	main.camera_center -= 0.37
	main.camera_lane_center += 0.42
	main._update_parallax_background()
	var after_y := node.position
	var y_shift := after_y.y - start_position.y
	if absf(absf(y_shift) - 0.42 * scale) > 1.8:
		_fail("World art Y shift is not tied to world scale: %.3f vs %.3f." % [y_shift, -0.42 * scale])
		return
	print("BATTLE_XY_BACKGROUND_PROBE world_art=%d scale=%.2f" % [main.world_background_art_nodes.size(), scale])
	quit()
