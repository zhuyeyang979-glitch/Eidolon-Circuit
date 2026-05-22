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
	main._update_editor_ui(true)
	main.editor_visual_refresh_skip_count = 0
	main.editor_board_shallow_node_snapshot_count = 0
	main.editor_board_base_snapshot_cache_key = ""
	main.editor_board_base_snapshot_cache = {}
	main._refresh_editor_visual_views({}, false)
	if int(main.editor_board_shallow_node_snapshot_count) <= 0:
		_fail("Initial custom board refresh did not use shallow node snapshot path.")
		return
	var shallow_after_first := int(main.editor_board_shallow_node_snapshot_count)
	main._refresh_editor_visual_views({}, false)
	if int(main.editor_board_shallow_node_snapshot_count) != shallow_after_first:
		_fail("Repeated board refresh rebuilt base model instead of using revision cache.")
		return
	if int(main.editor_visual_refresh_skip_count) <= 0 and int(main.editor_board_base_snapshot_hit_count) <= 0:
		_fail("Repeated board refresh did not skip or hit the base snapshot cache.")
		return
	print("EDITOR_BOARD_MODEL_INCREMENTAL_PROBE ok shallow=%d skip=%d" % [int(main.editor_board_shallow_node_snapshot_count), int(main.editor_visual_refresh_skip_count)])
	quit(0)
