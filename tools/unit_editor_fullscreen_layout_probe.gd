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
	if main.editor_power_topbar_view == null:
		_fail("Power topbar missing.")
	var board: Control = main.assembly_board_view
	var topbar: Control = main.editor_power_topbar_view
	if board.position.x > 12.0 or board.position.y > 104.0:
		_fail("Assembly board should start near the top-left of the Unit Edit work area.")
	if board.size.x < 880.0 or board.size.y < 520.0:
		_fail("Assembly board should fill the main Unit Edit work area.")
	if topbar.position.x > 12.0 or topbar.position.y > 32.0:
		_fail("Power allocation topbar should occupy the reclaimed header area.")
	if topbar.size.x < 880.0:
		_fail("Power allocation topbar should span the main Unit Edit width.")
	if main.editor_torso_detail_view == null or main.editor_torso_detail_view.size.x < 860.0:
		_fail("Torso detail panel should use the widened board area.")
	print("UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=%s topbar=%s" % [str(board.size), str(topbar.size)])
	quit()
