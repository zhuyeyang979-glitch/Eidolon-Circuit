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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var engine_index := _find(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 0.0)
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_drive_demand_for_part(part) > 0.0 and main._booster_boost_momentum_for_part(part) > 0.0)
	if torso_index < 0 or engine_index < 0 or booster_index < 0:
		_fail("Missing torso, engine, or boost-capable booster.")
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	unit["blank_canvas"] = false
	unit["role"] = "hero"
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "booster", "booster": booster_index, "torso_node": torso},
	]
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	main.editor_canvas_mode = "blank"
	main.editor_panel_mode = "parts"
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit
	main.editor_open_torso_node_index = torso
	main._activate_engine_allocation_target_for_torso(unit, torso)
	main._refresh_engine_momentum_allocation_view()
	var view = main.engine_momentum_allocation_view
	var booster_entry := {}
	var boost_entry := {}
	for raw_entry in view.entries:
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == "booster_drive":
			booster_entry = Dictionary(raw_entry)
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == "booster_boost_brake":
			boost_entry = Dictionary(raw_entry)
	if booster_entry.is_empty():
		_fail("Missing booster drive entry.")
	if boost_entry.is_empty():
		_fail("Missing booster boost/brake entry.")
	var fixed := float(booster_entry.get("momentum", 0.0))
	var extra := float(boost_entry.get("momentum", 0.0))
	var peak := float(booster_entry.get("boost_peak_momentum", 0.0))
	if fixed <= 0.0 or extra <= 0.0 or peak <= fixed:
		_fail("Booster entry should expose fixed demand and Boost peak demand.")
	if absf(peak - (fixed + extra)) > 0.01:
		_fail("Boost peak demand should be fixed demand plus Boost extra demand.")
	if not bool(booster_entry.get("boost_dash_hint", false)):
		_fail("Booster entry should mark the dashed Boost hint.")
	if float(booster_entry.get("boost_peak_ratio", 0.0)) <= float(booster_entry.get("ratio", 0.0)):
		_fail("Boost peak ratio should extend beyond fixed demand ratio.")
	var expected_used := float(booster_entry.get("ratio", 0.0)) + float(boost_entry.get("ratio", 0.0))
	if absf(float(view.used_ratio) - expected_used) > 0.001:
		_fail("Panel used_ratio should include drive + boost/brake rows when no limbs exist.")
	print("POWER_ALLOCATION_PANEL_BOOST_DASH_PROBE ok fixed=%.1f extra=%.1f peak=%.1f" % [fixed, extra, peak])
	quit()
