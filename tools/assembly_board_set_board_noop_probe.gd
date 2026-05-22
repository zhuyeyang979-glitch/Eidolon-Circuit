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
	main.editor_panel_mode = "parts"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	main._update_editor_ui()
	var board = main.assembly_board_view
	if board == null:
		_fail("Assembly board view missing.")
	var applied_before := int(board.set_board_apply_count)
	var noop_before := int(board.set_board_noop_count)
	var stats := main._editor_current_stats()
	main._refresh_editor_visual_views(stats)
	main._refresh_editor_visual_views(stats)
	if int(board.set_board_apply_count) != applied_before:
		_fail("Identical board refresh applied redraw/deep-copy again: before=%d after=%d" % [applied_before, int(board.set_board_apply_count)])
	if int(board.set_board_noop_count) <= noop_before:
		_fail("Identical board refresh did not register a no-op.")
	print("ASSEMBLY_BOARD_SET_BOARD_NOOP_PROBE ok apply=%d noop=%d" % [int(board.set_board_apply_count), int(board.set_board_noop_count)])
	quit()
