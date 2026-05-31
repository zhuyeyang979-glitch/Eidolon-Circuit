extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("barrier")
	main._reset_editor_working_canvas("barrier")
	main._update_editor_ui()
	var board_size: Vector2 = main.assembly_board_view.size
	var rect: Rect2 = main._barrier_editor_rect_for_size(board_size)
	if rect.size.x < board_size.x * 0.66 or rect.size.y < board_size.y * 0.66:
		_fail("Barrier editor rect does not occupy most of the visible board.")
	var top_left := main._barrier_board_cell_index(rect.position + Vector2(2.0, 2.0))
	var center := main._barrier_board_cell_index(rect.get_center())
	var bottom_right := main._barrier_board_cell_index(rect.end - Vector2(2.0, 2.0))
	if top_left != 0:
		_fail("Top-left barrier click did not map to cell 0.")
	if center < 20 or center > 29:
		_fail("Center barrier click did not map to the middle row.")
	if bottom_right != MainScene.BARRIER_MAP_COLUMNS * MainScene.BARRIER_MAP_ROWS - 1:
		_fail("Bottom-right barrier click did not map to the final cell.")
	print("BARRIER_EDITOR_SCREEN_PROBE rect=%.1fx%.1f tl=%d center=%d br=%d" % [
		rect.size.x,
		rect.size.y,
		top_left,
		center,
		bottom_right,
	])
	quit()
