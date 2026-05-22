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
	main._update_editor_ui(true)
	var board = main.assembly_board_view
	if board == null:
		_fail("Assembly board view missing.")
		return
	var apply_before := int(board.set_board_apply_count)
	var noop_before := int(board.set_board_noop_count)
	var submit_before := int(board.retained_render_submit_count)
	var skip_before := int(main.editor_visual_refresh_skip_count)
	var stats := main._editor_current_stats()
	main._refresh_editor_visual_views(stats)
	main._refresh_editor_visual_views(stats)
	if int(board.set_board_apply_count) > apply_before + 1:
		_fail("Repeated editor render refresh reapplied too many board snapshots.")
		return
	if int(board.set_board_noop_count) <= noop_before and int(main.editor_visual_refresh_skip_count) <= skip_before:
		_fail("Repeated editor render refresh neither skipped nor registered retained no-op.")
		return
	if int(board.retained_render_submit_count) < submit_before:
		_fail("Retained render submit counter regressed.")
		return
	print("EDITOR_RENDER_CACHE_PROBE ok apply=%d noop=%d skip=%d submit=%d" % [int(board.set_board_apply_count), int(board.set_board_noop_count), int(main.editor_visual_refresh_skip_count), int(board.retained_render_submit_count)])
	quit(0)
