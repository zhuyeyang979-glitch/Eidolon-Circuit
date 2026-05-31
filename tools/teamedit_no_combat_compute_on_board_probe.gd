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
	main.editor_panel_mode = "parts"
	main._update_editor_ui(true)
	main.flush_editor_dirty(0)
	main.editor_dirty_flags = 0
	var role_key: String = main.ROLE_ORDER[main.editor_role_index]
	var joint_catalog: Array = main._catalog_for(role_key, "joint")
	var limb_catalog: Array = main._catalog_for(role_key, "limb_muscle")
	if joint_catalog.is_empty() or limb_catalog.is_empty():
		_fail("Missing topology parts for board compute probe.")
		return
	var before_pair_loop := int(main.collision_pair_loop_count)
	var before_precise := int(main.collision_polygon_precise_check_count)
	var before_gpu_query := int(main.gpu_geometry_query_submit_count)
	var before_gpu_pairs := int(main.gpu_collision_pair_dispatch_count)
	var before_saved_scan := int(main.saved_unit_cache_disk_scan_count)
	main._drop_catalog_part_on_board("joint", 0, Vector2(300.0, 240.0))
	main._drop_catalog_part_on_board("limb_muscle", 0, Vector2(346.0, 240.0))
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._try_magnetic_link_for_node(unit_bp, 1)
	main._mark_editor_board_interaction_dirty("probe.no_combat_compute")
	var pair_delta := int(main.collision_pair_loop_count) - before_pair_loop
	var precise_delta := int(main.collision_polygon_precise_check_count) - before_precise
	var gpu_query_delta := int(main.gpu_geometry_query_submit_count) - before_gpu_query
	var gpu_pair_delta := int(main.gpu_collision_pair_dispatch_count) - before_gpu_pairs
	var saved_scan_delta := int(main.saved_unit_cache_disk_scan_count) - before_saved_scan
	if pair_delta != 0 or precise_delta != 0:
		_fail("Board path used CPU battle collision: pair=%d precise=%d" % [pair_delta, precise_delta])
		return
	if gpu_query_delta != 0 or gpu_pair_delta != 0:
		_fail("Board path submitted GPU battle geometry: query=%d pairs=%d" % [gpu_query_delta, gpu_pair_delta])
		return
	if saved_scan_delta != 0:
		_fail("Board path scanned saved-unit library: %d" % saved_scan_delta)
		return
	print("TEAMEDIT_NO_COMBAT_COMPUTE_ON_BOARD_PROBE ok pair=%d precise=%d gpu_query=%d gpu_pairs=%d saved_scan=%d" % [
		pair_delta,
		precise_delta,
		gpu_query_delta,
		gpu_pair_delta,
		saved_scan_delta,
	])
	quit(0)
