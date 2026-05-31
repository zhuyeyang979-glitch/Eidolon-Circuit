extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_index(main, slot_key: String) -> int:
	var catalog: Array = main._catalog_for("hero", slot_key)
	return 0 if not catalog.is_empty() else -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main._start_blank_topology()
	main._update_editor_ui(true)
	main.flush_editor_dirty(0)
	var part_index := _first_index(main, "limb_muscle")
	var slot_key := "limb_muscle"
	if part_index < 0:
		slot_key = "muscle"
		part_index = _first_index(main, "muscle")
	if part_index < 0:
		_fail("No part available.")
		return
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, slot_key, part_index)
	var a := main._add_topology_node_at(Vector2(250, 240))
	main._set_pending_canvas_part(unit_bp, slot_key, part_index)
	var b := main._add_topology_node_at(Vector2(330, 240))
	if a < 0 or b < 0:
		_fail("Could not create test nodes.")
		return
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var edges: Array = topology.get("edges", [])
	edges.append(main._topology_make_socket_edge(a, "distal", b, "root_joint"))
	topology["edges"] = edges
	unit_bp["custom_topology"] = topology
	main._refresh_editor_visual_views_fast_drag([a, b])
	main.editor_dirty_flags = 0
	var before_catalog := int(main.editor_catalog_card_update_count)
	var before_gpu := int(main.gpu_geometry_query_submit_count)
	main.hot_path_profiler.begin_interaction("teamedit.manual_connect_unlink")
	main.hot_path_profiler.begin_frame()
	if not main._unlink_topology_edge_at_index(unit_bp, 0):
		_fail("Unlink failed.")
		return
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.manual_connect_unlink")
	var catalog_delta := int(main.editor_catalog_card_update_count) - before_catalog
	var gpu_delta := int(main.gpu_geometry_query_submit_count) - before_gpu
	if catalog_delta != 0:
		_fail("Manual unlink refreshed catalog cards: %d" % catalog_delta)
		return
	if gpu_delta != 0:
		_fail("Manual unlink submitted GPU geometry queries: %d" % gpu_delta)
		return
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("teamedit.manual_connect_unlink")
	print("TEAMEDIT_MANUAL_CONNECT_UNLINK_BUDGET_PROBE ok p95=%.2fms max=%.2fms catalog_delta=%d gpu_delta=%d" % [
		float(stats.get("p95_usec", 0.0)) / 1000.0,
		float(stats.get("max_usec", 0.0)) / 1000.0,
		catalog_delta,
		gpu_delta,
	])
	quit(0)
