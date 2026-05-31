extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		var part: Dictionary = Dictionary(main._catalog_for("hero", slot)[i])
		if bool(predicate.call(part)):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_drive_allocation_min_for_part(part) > 0.0)
	if torso_index < 0 or booster_index < 0:
		_fail("Missing torso or booster.")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	unit["blank_canvas"] = false
	unit["role"] = "hero"
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main.editor_working_blueprint = unit
	main.editor_open_torso_node_index = torso
	main.editor_topology_node_index = torso
	var booster_part: Dictionary = main._selected_component("hero", "booster", booster_index)
	main._add_torso_payload_component("booster", booster_index, booster_part)
	var after_first: Array = Array(main._editor_current_blueprint().get("slot_payloads", []))
	if after_first.size() != 1 or String(Dictionary(after_first[0]).get("kind", "")) != "booster":
		_fail("First booster install failed.")
	main._add_torso_payload_component("booster", booster_index, booster_part)
	var after_second: Array = Array(main._editor_current_blueprint().get("slot_payloads", []))
	if after_second.size() != 1:
		_fail("Second booster should be rejected, payload count=%d" % after_second.size())
	var hint := ""
	if main.editor_summary_label != null:
		hint = String(main.editor_summary_label.text)
	if not (hint.contains("已有推进器") or hint.to_lower().contains("already has a booster")):
		_fail("Expected existing-booster warning, got: %s" % hint)
	print("SINGLE_BOOSTER_PER_TORSO_INSTALL_PROBE ok payloads=%d" % after_second.size())
	quit()
