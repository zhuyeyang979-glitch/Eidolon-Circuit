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
	main._start_blank_topology()
	main._update_editor_ui(true)
	var slot_key := "limb_muscle"
	var catalog: Array = main._catalog_for("hero", slot_key)
	if catalog.is_empty():
		slot_key = "muscle"
		catalog = main._catalog_for("hero", slot_key)
	if catalog.is_empty():
		_fail("No part available for drop probe.")
		return
	var board = main.assembly_board_view
	var before_body := int(board.retained_component_body_submit_count)
	var before_catalog := int(main.editor_catalog_card_update_count)
	var before_stats := int(main.editor_compute_unit_stats_count)
	var before_gpu := int(main.gpu_geometry_query_submit_count)
	main.hot_path_profiler.begin_interaction("teamedit.drop_release")
	main.hot_path_profiler.begin_frame()
	main._drop_catalog_part_on_board(slot_key, 0, Vector2(280.0, 240.0))
	main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.drop_release")
	var after_body := int(board.retained_component_body_submit_count)
	if after_body != before_body:
		_fail("Drop release submitted component body immediately: %d -> %d." % [before_body, after_body])
		return
	if int(board.retained_component_defer_count) <= 0:
		_fail("Drop release did not queue deferred retained body submit.")
		return
	if int(main.editor_catalog_card_update_count) != before_catalog:
		_fail("Drop release refreshed catalog cards.")
		return
	if int(main.gpu_geometry_query_submit_count) != before_gpu:
		_fail("Drop release submitted GPU/battle geometry query.")
		return
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("teamedit.drop_release")
	print("TEAMEDIT_DROP_NO_COMPONENT_SUBMIT_ON_RELEASE_PROBE ok max=%.2fms stats_delta=%d deferred=%d" % [
		float(stats.get("max_usec", 0.0)) / 1000.0,
		int(main.editor_compute_unit_stats_count) - before_stats,
		int(board.retained_component_defer_count),
	])
	quit(0)
