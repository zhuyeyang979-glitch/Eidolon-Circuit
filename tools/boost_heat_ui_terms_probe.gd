extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_engine(main) -> int:
	for i in range(main._catalog_for("hero", "engine").size()):
		if main._engine_momentum_output_for_part(main._selected_component("hero", "engine", i)) > 0.0:
			return i
	return -1


func _first_booster(main) -> int:
	for i in range(main._catalog_for("hero", "booster").size()):
		var part: Dictionary = main._selected_component("hero", "booster", i)
		if main._thruster_drive_allocation_min_for_part(part) > 0.0 and float(main._thruster_with_drive_defaults(part).get("boost_heat", 0.0)) > 0.0:
			return i
	return -1


func _build_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	unit["blank_canvas"] = false
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": _first_engine(main), "torso_node": torso},
		{"kind": "booster", "booster": _first_booster(main), "torso_node": torso},
	]
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _entry_with_kind(entries: Array, kind: String) -> Dictionary:
	for raw_entry in entries:
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == kind:
			return Dictionary(raw_entry)
	return {}


func _contains_required_terms(text: String) -> bool:
	var lower := text.to_lower()
	return (lower.find("boost") >= 0 and (lower.find("动量") >= 0 or lower.find("momentum") >= 0 or lower.find("b+") >= 0) and (lower.find("热耗") >= 0 or lower.find("heat cost") >= 0))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var booster: Dictionary = main._thruster_with_drive_defaults({
		"name": "Probe Thruster",
		"thruster_family": "cruise_blue",
		"drive_demand": 20.0,
		"momentum_min": 20.0,
		"allocated_momentum": 20.0,
		"boost_momentum": 25.0,
		"boost_efficiency": 2.0,
		"boost_duration": 0.3,
		"boost_heat": 6.0,
		"boost_cooldown": 0.5,
		"slot_volume_tier": "S",
	})
	var text := "\n".join(main._catalog_card_data_lines("booster", booster))
	text += "\n" + "\n".join(main._hover_card_player_detail_lines("booster", booster))
	for raw_stat in main._hover_card_stat_entries("booster", booster):
		if raw_stat is Dictionary:
			text += "\n%s" % String(Dictionary(raw_stat).get("label", ""))
	if not _contains_required_terms(text):
		_fail("Booster card/hover should distinguish Boost momentum and heat cost: %s" % text)
	var current := {
		"blank_canvas": false,
		"role": "hero",
		"cost": 0,
		"deploy_cost": 0,
		"software_payload_count": 0,
		"slot_payload_count": 0,
		"module_slots": 0,
		"torso_slots": 0,
		"health": 100,
		"shield_max": 0,
		"mass": 20.0,
		"drive_output_total": 100.0,
		"drive_demand_total": 60.0,
		"cooling": 40.0,
		"idle_heat_load": 10.0,
		"heat_capacity": 100.0,
		"boost_heat": 6.0,
		"boost_momentum": 120.0,
		"boost_total_momentum": 120.0,
		"boost_speed": 6.0,
		"move_speed": 3.0,
		"move_momentum": 40.0,
	}
	var entries: Array = main._editor_stats_entries(current, current.duplicate(true), {"cost": 0, "units": 0}, {"cost": 0, "units": 0}, {})
	var saw_heat_cost := false
	var saw_boost_momentum := false
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var label := String(Dictionary(raw_entry).get("label", ""))
		if label.find("单次Boost热耗") >= 0 or label.find("Boost Heat Cost") >= 0:
			saw_heat_cost = true
		if label.find("Boost动量") >= 0 or label.find("Boost总动量") >= 0 or label.find("Boost Momentum") >= 0 or label.find("Total Boost Momentum") >= 0:
			saw_boost_momentum = true
	if not saw_heat_cost or not saw_boost_momentum:
		_fail("Stats rail should show both Boost momentum and single-use heat cost.")
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	main._update_editor_ui()
	var data: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), 0, 0)
	var boost_entry := _entry_with_kind(Array(data.get("entries", [])), "booster_boost_brake")
	if boost_entry.is_empty():
		_fail("Torso detail allocation should expose a Boost/brake row.")
	var boost_line := "%s\n%s" % [String(boost_entry.get("line", "")), String(boost_entry.get("heat_label", ""))]
	if boost_line.find("单次Boost热耗") < 0 and boost_line.to_lower().find("heat cost") < 0:
		_fail("Boost/brake allocation row should state single-use boost heat cost: %s" % boost_line)
	print("BOOST_HEAT_UI_TERMS_PROBE ok")
	quit()
