extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		if bool(predicate.call(Dictionary(main._catalog_for("hero", slot)[i]))):
			return i
	return -1


func _build_current_unit(main) -> Dictionary:
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
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var bp: Dictionary = _build_current_unit(main)
	bp["unit_name"] = "Probe Saved Team Unit"
	var entry := {"unit_library": true, "path": "probe://saved_team_unit", "role": "hero", "blueprint": bp, "unit_name": "Probe Saved Team Unit"}
	var team_path: String = main._save_team_from_saved_unit_selection("Probe Saved Team", [entry])
	if team_path == "":
		_fail("Failed to save team from selected saved units.")
	var teams := main._saved_teams_entries(true)
	var found := false
	for raw_team in teams:
		if raw_team is Dictionary and String(Dictionary(raw_team).get("path", "")) == team_path:
			found = true
			break
	if not found:
		_fail("Saved team should appear in saved team entries.")
	if not main._load_saved_team_to_current_roster(team_path):
		_fail("Saved team should load into current roster.")
	print("SAVED_UNITS_SAVED_TEAM_VIEW_PROBE ok path=%s" % team_path)
	quit()
