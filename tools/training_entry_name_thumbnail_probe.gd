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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var torso_index := _first_torso(main)
	if torso_index < 0:
		_fail("Missing torso.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["unit_name"] = "Probe Training Unit"
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var segments: Array = Array(stats.get("runtime_topology_segments", []))
	if segments.is_empty():
		_fail("Training thumbnail source has no runtime topology segments.")
	main.training_entry_intro_view.set_entries([
		{"player_id": 1, "label": "PLAYER", "name": "Probe Training Unit", "segments": segments},
	], "en", 1.0)
	if not main.training_entry_intro_view.visible:
		_fail("Training entry intro did not become visible.")
	if main.training_entry_intro_view.entries.size() != 1:
		_fail("Training entry intro did not keep one entry.")
	var entry: Dictionary = Dictionary(main.training_entry_intro_view.entries[0])
	if String(entry.get("name", "")) != "Probe Training Unit":
		_fail("Training entry intro did not preserve the unit name.")
	var bounds: Rect2 = main.training_entry_intro_view._segment_bounds(segments)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		_fail("Training thumbnail bounds are invalid.")
	print("TRAINING_ENTRY_NAME_THUMBNAIL_PROBE ok name=%s aspect=%.3f" % [String(entry.get("name", "")), bounds.size.x / bounds.size.y])
	quit()
