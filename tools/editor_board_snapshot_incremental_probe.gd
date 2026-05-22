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
	main._update_editor_ui(true)
	main._refresh_editor_visual_views()
	var rebuilds := int(main.editor_board_base_snapshot_rebuild_count)
	var dynamic_applies := int(main.editor_board_dynamic_overlay_apply_count)
	main.editor_topology_node_index = 0
	main.editor_selected_topology_nodes = [0]
	main._refresh_editor_visual_views()
	if int(main.editor_board_base_snapshot_rebuild_count) != rebuilds:
		_fail("Selection-only refresh rebuilt base board snapshot.")
	if int(main.editor_board_dynamic_overlay_apply_count) <= dynamic_applies:
		_fail("Selection-only refresh did not apply dynamic overlay.")
	main.editor_board_zoom = clampf(main.editor_board_zoom + 0.05, MainScene.EDITOR_BOARD_ZOOM_MIN, MainScene.EDITOR_BOARD_ZOOM_MAX)
	main._refresh_editor_visual_views()
	if int(main.editor_board_base_snapshot_rebuild_count) != rebuilds:
		_fail("Zoom-only refresh rebuilt base board snapshot.")
	print("EDITOR_BOARD_SNAPSHOT_INCREMENTAL_PROBE ok rebuilds=%d dynamic=%d" % [
		int(main.editor_board_base_snapshot_rebuild_count),
		int(main.editor_board_dynamic_overlay_apply_count),
	])
	quit(0)
