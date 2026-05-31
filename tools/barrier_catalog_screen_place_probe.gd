extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	await process_frame
	main.editor_role_index = MainScene.ROLE_ORDER.find("barrier")
	main._show_editor()
	main.editor_panel_mode = "parts"
	main._update_editor_ui(true)
	var unit_bp: Dictionary = main._editor_current_blueprint()
	if not main._barrier_uses_screen_board(unit_bp):
		_fail("Blank barrier should use the screen board path.")
	if main.editor_part_group_mode != "barrier_panel" or main.editor_part_filter_mode != "barrier_muscle":
		_fail("Barrier editor should default to barrier_panel/barrier_muscle, got %s/%s." % [main.editor_part_group_mode, main.editor_part_filter_mode])
	var entries: Array = main._editor_catalog_entries("barrier", String(MainScene.BUILD_SLOTS[main.editor_slot_index]))
	var gravity_pos := _entry_position(entries, "MAZE RIGHT GRAVITY FLOOR PANEL")
	var coolant_pos := _entry_position(entries, "MAZE COOLANT FLOOR PANEL")
	if gravity_pos < 0 or coolant_pos < 0:
		_fail("Barrier panel catalog did not expose maze gravity/coolant panels.")
	var gravity_entry: Dictionary = entries[gravity_pos]
	var coolant_entry: Dictionary = entries[coolant_pos]
	var gravity_index := int(gravity_entry.get("index", -1))
	var coolant_index := int(coolant_entry.get("index", -1))
	var gravity_slot := String(gravity_entry.get("slot", ""))
	var coolant_slot := String(coolant_entry.get("slot", ""))
	if gravity_slot != "muscle" or coolant_slot != "muscle":
		_fail("Focused panels should resolve to muscle catalog entries.")
	_select_catalog_entry(main, gravity_pos)
	if main.editor_pending_place_slot != "muscle" or main.editor_pending_place_index != gravity_index:
		_fail("Clicking a barrier panel card should set pending muscle placement.")
	var board_size: Vector2 = main.assembly_board_view.size
	var rect: Rect2 = main._barrier_editor_rect_for_size(board_size)
	var expected_aspect := MainScene.BARRIER_BLUEPRINT_WIDTH / MainScene.BARRIER_BLUEPRINT_HEIGHT
	var actual_aspect := rect.size.x / rect.size.y
	if absf(actual_aspect - expected_aspect) > 0.01:
		_fail("Barrier board aspect should match battle screen %.3f, got %.3f." % [expected_aspect, actual_aspect])
	var first_pos := Vector2(0.26, 0.44)
	var cell_index := _legacy_cell_for_pos(first_pos)
	var cell_center := _screen_pos_to_board(main, first_pos)
	_click_board(main, cell_center, MOUSE_BUTTON_LEFT)
	unit_bp = main._editor_current_blueprint()
	_assert_tile(unit_bp, first_pos, "muscle", gravity_index, "click placement")
	_assert_runtime_tile(main, unit_bp, first_pos, gravity_index)
	_select_catalog_entry(main, coolant_pos)
	_click_board(main, cell_center, MOUSE_BUTTON_LEFT)
	unit_bp = main._editor_current_blueprint()
	_assert_tile(unit_bp, first_pos, "muscle", coolant_index, "replacement")
	_click_board(main, cell_center, MOUSE_BUTTON_RIGHT)
	unit_bp = main._editor_current_blueprint()
	if _tile_near_pos(unit_bp, first_pos).size() != 0:
		_fail("Right-click should remove the selected barrier tile.")
	main._drop_catalog_part_on_board("muscle", gravity_index, cell_center)
	unit_bp = main._editor_current_blueprint()
	_assert_tile(unit_bp, first_pos, "muscle", gravity_index, "drag/drop placement")
	var guides_before: bool = bool(main.editor_barrier_grid_guides_enabled)
	main._editor_action("toggle_barrier_grid")
	if main.editor_barrier_grid_guides_enabled == guides_before:
		_fail("Grid guide toggle did not flip editor_barrier_grid_guides_enabled.")
	main._refresh_editor_visual_views({}, false)
	if bool(main.assembly_board_view.board_snapshot.get("show_grid_guides", guides_before)) != main.editor_barrier_grid_guides_enabled:
		_fail("Barrier board snapshot did not receive the grid guide toggle.")
	var zoom_before: float = float(main.editor_board_zoom)
	main._set_editor_board_zoom(1.4, rect.get_center())
	var zoom_rect: Rect2 = main._barrier_editor_rect_for_size(board_size)
	if main.editor_board_zoom <= zoom_before or absf((zoom_rect.size.x / zoom_rect.size.y) - expected_aspect) > 0.01:
		_fail("Barrier screen board should zoom while preserving battle screen aspect.")
	var zoom_center_pos := main._barrier_board_screen_pos(zoom_rect.get_center())
	if zoom_center_pos.distance_to(Vector2(0.5, 0.5)) > 0.01:
		_fail("Zoomed barrier board center should still map to normalized screen center.")
	print("BARRIER_CATALOG_SCREEN_PLACE_PROBE ok pending=%s/%d cell=%d drag=%d grid=%s zoom=%.2f" % [
		main.editor_pending_place_slot,
		main.editor_pending_place_index,
		cell_index,
		gravity_index,
		str(main.editor_barrier_grid_guides_enabled),
		main.editor_board_zoom,
	])
	quit(0)


func _entry_position(entries: Array, part_name: String) -> int:
	for i in range(entries.size()):
		if not (entries[i] is Dictionary):
			continue
		var entry: Dictionary = entries[i]
		var part: Dictionary = entry.get("part", {})
		if String(part.get("name", "")) == part_name:
			return i
	return -1


func _select_catalog_entry(main, entry_position: int) -> void:
	var page_size: int = maxi(1, main.editor_catalog_buttons.size())
	main.editor_catalog_page = int(floori(float(entry_position) / float(page_size)))
	main._select_catalog_component(entry_position % page_size)


func _cell_center(main, cell_index: int) -> Vector2:
	var rect: Rect2 = main._barrier_editor_rect_for_size(main.assembly_board_view.size)
	var cell_size := Vector2(rect.size.x / float(MainScene.BARRIER_MAP_COLUMNS), rect.size.y / float(MainScene.BARRIER_MAP_ROWS))
	var col := cell_index % MainScene.BARRIER_MAP_COLUMNS
	var row := int(floori(float(cell_index) / float(MainScene.BARRIER_MAP_COLUMNS)))
	return rect.position + Vector2(float(col) + 0.5, float(row) + 0.5) * cell_size


func _screen_pos_to_board(main, pos: Vector2) -> Vector2:
	var rect: Rect2 = main._barrier_editor_rect_for_size(main.assembly_board_view.size)
	return rect.position + Vector2(clampf(pos.x, 0.0, 1.0) * rect.size.x, clampf(pos.y, 0.0, 1.0) * rect.size.y)


func _click_board(main, position: Vector2, button_index: int) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = true
	event.position = position
	main._handle_editor_board_input(event)


func _legacy_cell_for_pos(pos: Vector2) -> int:
	var x := clampi(int(floor(pos.x * float(MainScene.BARRIER_MAP_COLUMNS))), 0, MainScene.BARRIER_MAP_COLUMNS - 1)
	var y := clampi(int(floor(pos.y * float(MainScene.BARRIER_MAP_ROWS))), 0, MainScene.BARRIER_MAP_ROWS - 1)
	return y * MainScene.BARRIER_MAP_COLUMNS + x


func _tile_near_pos(unit_bp: Dictionary, pos: Vector2) -> Dictionary:
	for raw_tile in Array(unit_bp.get("barrier_tiles", [])):
		if raw_tile is Dictionary:
			var tile: Dictionary = raw_tile
			var tile_pos: Vector2 = tile.get("pos", Vector2(-1.0, -1.0)) if tile.get("pos", null) is Vector2 else Vector2(-1.0, -1.0)
			if tile_pos.distance_to(pos) < 0.001:
				return tile
	return {}


func _assert_tile(unit_bp: Dictionary, pos: Vector2, slot_key: String, part_index: int, label: String) -> void:
	var tile := _tile_near_pos(unit_bp, pos)
	if tile.is_empty():
		_fail("%s did not write a barrier tile." % label)
	if tile.has("index"):
		_fail("%s should save new barrier placement as pos, not index: %s." % [label, str(tile)])
	if not tile.has(slot_key) or int(tile.get(slot_key, -1)) != part_index:
		_fail("%s wrote unexpected tile payload: %s." % [label, str(tile)])


func _assert_runtime_tile(main, unit_bp: Dictionary, pos: Vector2, part_index: int) -> void:
	var stats: Dictionary = main._compute_unit_stats(1, "barrier", -1, unit_bp)
	var runtime_tile := {}
	for raw_tile in Array(stats.get("barrier_map_tiles", [])):
		if raw_tile is Dictionary and Dictionary(raw_tile).get("pos", Vector2.ZERO) is Vector2:
			var candidate: Dictionary = raw_tile
			if Vector2(candidate.get("pos")).distance_to(pos) < 0.001:
				runtime_tile = candidate
				break
	if runtime_tile.is_empty():
		_fail("Placed barrier tile did not enter runtime barrier_map_tiles.")
	var expected_ring := pos.x * MainScene.BARRIER_BLUEPRINT_WIDTH - MainScene.BARRIER_BLUEPRINT_WIDTH * 0.5
	var expected_lane := pos.y * MainScene.BARRIER_BLUEPRINT_HEIGHT - MainScene.BARRIER_BLUEPRINT_HEIGHT * 0.5
	if absf(float(runtime_tile.get("local_ring", 999.0)) - expected_ring) > 0.001:
		_fail("Runtime local_ring mismatch for placed tile: %s." % str(runtime_tile))
	if absf(float(runtime_tile.get("local_lane", 999.0)) - expected_lane) > 0.001:
		_fail("Runtime local_lane mismatch for placed tile: %s." % str(runtime_tile))
	if not Array(runtime_tile.get("effect_tags", [])).has("gravity"):
		_fail("Gravity barrier panel should carry gravity effect tag into runtime tile.")
	var catalog_part: Dictionary = main._selected_component("barrier", "muscle", part_index)
	if not bool(catalog_part.get("barrier_panel", false)) or not bool(catalog_part.get("barrier_tile_component", false)):
		_fail("Placed catalog part lost barrier panel flags.")
