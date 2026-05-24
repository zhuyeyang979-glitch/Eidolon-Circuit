extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_index(main, slot_key: String) -> int:
	var role_key: String = main.ROLE_ORDER[main.editor_role_index]
	var catalog: Array = main._catalog_for(role_key, slot_key)
	return 0 if not catalog.is_empty() else -1


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var module_part: Dictionary = main._catalog_for("hero", "module")[i]
		if String(module_part.get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _metric_snapshot(main) -> Dictionary:
	var sync_wait := 0
	if main.gpu_collision_pipeline != null:
		sync_wait = int(main.gpu_collision_pipeline.total_sync_wait_usec)
	return {
		"ui_writes": int(main.editor_property_write_count),
		"catalog_updates": int(main.editor_catalog_card_update_count),
		"board_enrich": 0,
		"visual_refresh": int(main.editor_visual_refresh_count),
		"stats": int(main.editor_compute_unit_stats_count),
		"saved_scan": int(main.saved_unit_cache_disk_scan_count),
		"gpu_submit": int(main.gpu_geometry_query_submit_count),
		"gpu_sync": sync_wait,
	}


func _metric_delta(now: Dictionary, before: Dictionary, key: String) -> int:
	return int(now.get(key, 0)) - int(before.get(key, 0))


func _reset_gesture_noise(main) -> void:
	main.editor_dirty_flags = 0
	main.editor_board_stats_idle_due_msec = -1
	main.editor_board_stats_idle_reason = ""


func _leaf_text(main, interaction: String) -> String:
	var leaves: Array = main.hot_path_profiler.interaction_hot_scopes(interaction, 4, true)
	var texts: Array = []
	for leaf in leaves:
		if leaf is Dictionary:
			texts.append("%s:%.2fms" % [
				String(Dictionary(leaf).get("name", "")),
				float(Dictionary(leaf).get("usec", 0)) / 1000.0,
			])
	return ",".join(texts)


func _summary_line(main, interaction: String, before: Dictionary) -> String:
	var stats: Dictionary = main.hot_path_profiler.interaction_stats(interaction)
	var now := _metric_snapshot(main)
	return "%s p95=%.2fms max=%.2fms hot=%s ui=%d catalog=%d board_enrich=%d visual=%d stats=%d saved_scan=%d gpu_submit=%d gpu_sync_usec=%d leaf=%s" % [
		interaction,
		float(stats.get("p95_usec", 0)) / 1000.0,
		float(stats.get("max_usec", 0)) / 1000.0,
		String(stats.get("hot_scope", "")),
		_metric_delta(now, before, "ui_writes"),
		_metric_delta(now, before, "catalog_updates"),
		_metric_delta(now, before, "board_enrich"),
		_metric_delta(now, before, "visual_refresh"),
		_metric_delta(now, before, "stats"),
		_metric_delta(now, before, "saved_scan"),
		_metric_delta(now, before, "gpu_submit"),
		_metric_delta(now, before, "gpu_sync"),
		_leaf_text(main, interaction),
	]


func _run_catalog_click_and_page(main, lines: Array) -> void:
	main.editor_panel_mode = "parts"
	main._update_editor_ui(true)
	main.flush_editor_dirty(0)
	_reset_gesture_noise(main)
	var button: Button = null
	for raw_button in main.editor_catalog_buttons:
		if raw_button is Button and raw_button.visible and not raw_button.disabled:
			button = raw_button
			break
	if button == null:
		_fail("No visible catalog button for performance profile.")
		return
	var before := _metric_snapshot(main)
	main.hot_path_profiler.begin_interaction("teamedit.catalog_click_page")
	for i in range(5):
		main.hot_path_profiler.begin_frame()
		main.ui_mouse_click_latch_msec = 0
		main._trigger_button_mouse_fallback(button)
		if i % 2 == 0:
			main._editor_action("next_catalog")
		else:
			main._editor_action("prev_catalog")
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.catalog_click_page")
	lines.append(_summary_line(main, "teamedit.catalog_click_page", before))


func _run_drag_to_board(main, lines: Array) -> void:
	main._start_blank_topology()
	main.editor_panel_mode = "parts"
	main._update_editor_ui(true)
	main.flush_editor_dirty(0)
	_reset_gesture_noise(main)
	var slot_key := "limb_muscle"
	var part_index := _first_index(main, slot_key)
	if part_index < 0:
		slot_key = "muscle"
		part_index = _first_index(main, slot_key)
	if part_index < 0:
		_fail("No topology part available for drag-to-board performance profile.")
		return
	var before := _metric_snapshot(main)
	main.hot_path_profiler.begin_interaction("teamedit.drag_to_board")
	for i in range(6):
		main.hot_path_profiler.begin_frame()
		main._drop_catalog_part_on_board(slot_key, part_index, Vector2(250.0 + float(i) * 28.0, 220.0))
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.drag_to_board")
	lines.append(_summary_line(main, "teamedit.drag_to_board", before))


func _run_existing_node_release(main, lines: Array) -> void:
	main._start_blank_topology()
	var slot_key := "limb_muscle"
	var part_index := _first_index(main, slot_key)
	if part_index < 0:
		slot_key = "muscle"
		part_index = _first_index(main, slot_key)
	if part_index < 0:
		_fail("No part available for existing-node performance profile.")
		return
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, slot_key, part_index)
	var node_index: int = main._add_topology_node_at(Vector2(260, 220))
	if node_index < 0:
		_fail("Could not create node for existing-node performance profile.")
		return
	main._refresh_editor_visual_views_fast_drag([node_index])
	_reset_gesture_noise(main)
	var before := _metric_snapshot(main)
	main.hot_path_profiler.begin_interaction("teamedit.existing_node_release")
	for i in range(10):
		main.hot_path_profiler.begin_frame()
		main.editor_dragging_node_index = node_index
		main._move_custom_node_to(unit_bp, node_index, Vector2(280 + i * 5, 240 + i * 2))
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.begin_frame()
	main.editor_dragging_node_index = node_index
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(330, 260)
	main._handle_editor_board_input(release)
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.existing_node_release")
	lines.append(_summary_line(main, "teamedit.existing_node_release", before))


func _run_manual_unlink(main, lines: Array) -> void:
	main._start_blank_topology()
	var slot_key := "limb_muscle"
	var part_index := _first_index(main, slot_key)
	if part_index < 0:
		slot_key = "muscle"
		part_index = _first_index(main, slot_key)
	if part_index < 0:
		_fail("No part available for manual unlink performance profile.")
		return
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, slot_key, part_index)
	var a: int = main._add_topology_node_at(Vector2(250, 240))
	main._set_pending_canvas_part(unit_bp, slot_key, part_index)
	var b: int = main._add_topology_node_at(Vector2(330, 240))
	if a < 0 or b < 0:
		_fail("Could not create manual unlink nodes.")
		return
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var edges: Array = topology.get("edges", [])
	edges.append(main._topology_make_socket_edge(a, "distal", b, "root_joint"))
	topology["edges"] = edges
	unit_bp["custom_topology"] = topology
	main._refresh_editor_visual_views_fast_drag([a, b])
	_reset_gesture_noise(main)
	var before := _metric_snapshot(main)
	main.hot_path_profiler.begin_interaction("teamedit.manual_unlink")
	main.hot_path_profiler.begin_frame()
	if not main._unlink_topology_edge_at_index(unit_bp, 0):
		_fail("Manual unlink failed in performance profile.")
		return
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.manual_unlink")
	lines.append(_summary_line(main, "teamedit.manual_unlink", before))


func _run_bottom_buttons(main, lines: Array) -> void:
	main._show_editor()
	main.editor_panel_mode = "parts"
	main._update_editor_ui(true)
	_reset_gesture_noise(main)
	var before := _metric_snapshot(main)
	main.hot_path_profiler.begin_interaction("teamedit.bottom_buttons")
	for action in ["save_canvas", "open_saved_units"]:
		main.hot_path_profiler.begin_frame()
		main._editor_action(action)
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.bottom_buttons")
	lines.append(_summary_line(main, "teamedit.bottom_buttons", before))


func _build_bound_unit(main) -> Dictionary:
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link module missing for performance profile.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.50), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "software_slot_index": 0, "torso_node": torso}]
	unit_bp["module_bindings"] = [{"payload_index": 0, "module_index": module_index, "attack_key": 1, "target_nodes": [limb_a, limb_b]}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _run_bound_pose(main, lines: Array) -> void:
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_board_tool = "pose"
	main.editor_working_role_key = "hero"
	main.editor_canvas_mode = "blank"
	main.editor_working_blueprint = _build_bound_unit(main)
	main._refresh_editor_visual_views({}, false)
	for _warm in range(4):
		main._tick_editor_visuals(1.0 / 60.0)
	_reset_gesture_noise(main)
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var root_index := 1
	var pivot: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, Dictionary(unit_bp.get("custom_topology", {})).get("edges", []), root_index, "root_joint")
	var start_local: Vector2 = main._topology_position_to_board_local(pivot + Vector2.RIGHT * 0.12)
	var before := _metric_snapshot(main)
	main.hot_path_profiler.begin_interaction("teamedit.bound_pose_drag")
	main.hot_path_profiler.begin_frame()
	if not main._start_editor_pose_drag(unit_bp, root_index, start_local, [1, 2]):
		_fail("Could not start bound pose drag in performance profile.")
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	for i in range(12):
		main.hot_path_profiler.begin_frame()
		var angle := 0.35 + float(i) * 0.045
		for j in range(3):
			var local: Vector2 = main._topology_position_to_board_local(pivot + Vector2(cos(angle + float(j) * 0.01), sin(angle + float(j) * 0.01)) * 0.14)
			main._update_editor_pose_drag(unit_bp, local)
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.begin_frame()
	main._finish_editor_pose_drag(unit_bp)
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.bound_pose_drag")
	lines.append(_summary_line(main, "teamedit.bound_pose_drag", before))


func _run_saved_units(main, lines: Array) -> void:
	main._show_saved_units_library("menu")
	main.saved_units_controller.mark_dirty("performance_profile")
	var before_page := _metric_snapshot(main)
	main.hot_path_profiler.begin_interaction("saved_units.page_hover")
	for i in range(18):
		main.hot_path_profiler.begin_frame()
		main._update_saved_units_ui()
		main._update_saved_units_hover(Vector2(86.0, 168.0 + float(i % 6) * 72.0))
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("saved_units.page_hover")
	lines.append(_summary_line(main, "saved_units.page_hover", before_page))


func _run_battle_tick(main, lines: Array) -> void:
	var before := _metric_snapshot(main)
	main.hot_path_profiler.begin_interaction("battle.tick_300")
	for i in range(300):
		main.hot_path_profiler.begin_frame()
		main._tick_battle(MainScene.BATTLE_FRAME_DELTA)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("battle.tick_300")
	lines.append(_summary_line(main, "battle.tick_300", before))


func _new_profile_main():
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._apply_performance_profile("balanced_4080s", true)
	return main


func _init() -> void:
	var lines: Array = []
	var main = _new_profile_main()
	main._show_editor()
	_run_catalog_click_and_page(main, lines)
	main.queue_free()
	main = _new_profile_main()
	main._show_editor()
	_run_drag_to_board(main, lines)
	main.queue_free()
	main = _new_profile_main()
	main._show_editor()
	_run_existing_node_release(main, lines)
	main.queue_free()
	main = _new_profile_main()
	main._show_editor()
	_run_manual_unlink(main, lines)
	main.queue_free()
	main = _new_profile_main()
	main._show_editor()
	_run_bottom_buttons(main, lines)
	main.queue_free()
	main = _new_profile_main()
	_run_bound_pose(main, lines)
	main.queue_free()
	main = _new_profile_main()
	_run_saved_units(main, lines)
	main.queue_free()
	main = _new_profile_main()
	_run_battle_tick(main, lines)
	var slow: Array = []
	for line in lines:
		print(line)
		var text := String(line)
		var p95_pos := text.find("p95=")
		var max_pos := text.find(" max=")
		if p95_pos >= 0 and max_pos > p95_pos:
			var p95_text := text.substr(p95_pos + 4, max_pos - p95_pos - 6)
			if float(p95_text) > 8.3:
				slow.append(text)
	if not slow.is_empty():
		print("PERFORMANCE_PROFILE_4080S_PROBE hot_scopes=%s" % " | ".join(slow))
	print("PERFORMANCE_PROFILE_4080S_PROBE ok interactions=%d profile=%s" % [lines.size(), main.performance_profile])
	quit(0)
