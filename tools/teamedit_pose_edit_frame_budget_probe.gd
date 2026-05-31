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
	main._refresh_editor_visual_views()
	var board = main.assembly_board_view
	var root_redraws := int(board.root_redraw_request_count)
	main.editor_pose_root_node = 0
	main.editor_pose_downstream_nodes = [0]
	main._refresh_editor_visual_views()
	if int(board.root_redraw_request_count) != root_redraws:
		_fail("Pose overlay refresh requested root board redraw.")
	print("TEAMEDIT_POSE_EDIT_FRAME_BUDGET_PROBE ok root_redraw=%d component_updates=%d" % [
		int(board.root_redraw_request_count),
		int(board.retained_component_update_count),
	])
	quit(0)
