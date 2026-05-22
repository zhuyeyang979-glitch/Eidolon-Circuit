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
	if main.assembly_board_view == null:
		_fail("AssemblyBoardView missing.")
	if String(main.editor_board_snapshot_cache_key) == "":
		_fail("Initial TeamEdit update did not build a board snapshot cache key.")
	main.editor_board_snapshot_cache_hit_count = 0
	main.editor_board_snapshot_rebuild_count = 0
	var stats := main._editor_current_stats()
	main._refresh_editor_visual_views(stats)
	main._refresh_editor_visual_views(stats)
	if int(main.editor_board_snapshot_rebuild_count) != 0:
		_fail("Identical visual refresh rebuilt board snapshot %d time(s)." % int(main.editor_board_snapshot_rebuild_count))
	if int(main.editor_board_snapshot_cache_hit_count) < 2:
		_fail("Identical visual refresh did not hit board snapshot cache enough: %d" % int(main.editor_board_snapshot_cache_hit_count))
	print("EDITOR_BOARD_SNAPSHOT_LAZY_PROBE ok hits=%d rebuild=%d" % [int(main.editor_board_snapshot_cache_hit_count), int(main.editor_board_snapshot_rebuild_count)])
	quit()
