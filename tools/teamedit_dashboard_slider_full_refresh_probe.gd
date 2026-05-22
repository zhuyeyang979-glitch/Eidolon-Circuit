extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		if bool(predicate.call(main._selected_component("hero", slot, i))):
			return i
	return -1


func _build_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var engine_index := _find(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 0.0)
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_allocated_momentum_for_part(part) > 0.0)
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	unit["blank_canvas"] = false
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "booster", "booster": booster_index, "torso_node": torso},
	]
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	return unit


func _first_id(data: Dictionary, kind: String) -> String:
	for entry in Array(data.get("entries", [])):
		if entry is Dictionary and String(Dictionary(entry).get("kind", "")) == kind:
			return String(Dictionary(entry).get("id", ""))
	return ""


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	main.editor_panel_mode = "parts"
	main._open_engine_momentum_allocation_for_payload(0)
	var data: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var pool := float(data.get("engine_output", 0.0))
	var booster_id := _first_id(data, "booster")
	if booster_id == "":
		_fail("Missing booster allocation entry.")
	main.editor_update_ui_count = 0
	main.editor_allocation_full_refresh_count = 0
	main._set_engine_momentum_allocation_ratio(booster_id, 0.31)
	main._finish_engine_momentum_allocation_drag(booster_id)
	var payloads: Array = Array(main._editor_current_blueprint().get("slot_payloads", []))
	var booster_payload: Dictionary = payloads[1]
	if absf(float(booster_payload.get("allocated_momentum", -1.0)) - pool * 0.31) > 0.01:
		_fail("Slider did not write allocation to booster payload.")
	if int(main.editor_allocation_full_refresh_count) <= 0 or int(main.editor_update_ui_count) <= 0:
		_fail("Slider finish did not trigger full dashboard/editor refresh.")
	if main.editor_summary_label == null or main.editor_summary_label.text == "":
		_fail("Dashboard summary did not refresh.")
	print("TEAMEDIT_DASHBOARD_SLIDER_FULL_REFRESH_PROBE ok full=%d ui=%d" % [int(main.editor_allocation_full_refresh_count), int(main.editor_update_ui_count)])
	quit()
