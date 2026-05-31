extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	if main.assembly_board_view == null:
		_fail("Assembly board view missing.")
	if main.editor_power_dock_view == null:
		_fail("Power dock missing.")
	var board: Control = main.assembly_board_view
	var dock: Control = main.editor_power_dock_view
	if board.position.x > 12.0 or board.position.y > 104.0:
		_fail("Assembly board should start near the top-left of the Unit Edit work area.")
	if board.size.x < 880.0 or board.size.y < 520.0:
		_fail("Assembly board should fill the main Unit Edit work area.")
	if dock.position.x < 180.0 or dock.position.y > 32.0:
		_fail("Power allocation dock should occupy the reclaimed header area while leaving the dashboard clear.")
	if dock.size.x < 700.0:
		_fail("Power allocation dock should provide the row-slider table in the header area.")
	if main.editor_torso_detail_view == null or main.editor_torso_detail_view.size.x < 860.0:
		_fail("Torso detail panel should use the widened board area.")
	print("UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=%s dock=%s" % [str(board.size), str(dock.size)])
	quit()
