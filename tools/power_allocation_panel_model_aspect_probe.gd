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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var torso_index := _first_torso(main)
	var engine_index := _first_engine(main)
	if torso_index < 0 or engine_index < 0:
		_fail("Missing torso or engine.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "engine", "engine": engine_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = torso
	main._activate_engine_allocation_target_for_torso(unit_bp, torso)
	main._open_dashboard_engine_allocation()
	var view = main.engine_momentum_allocation_view
	if view == null or not view.visible:
		_fail("Power allocation panel did not open.")
	var bounds: Rect2 = view._segment_bounds()
	var scale: float = view._silhouette_scale()
	if scale <= 0.0:
		_fail("Silhouette scale is invalid.")
	var rect: Rect2 = view._silhouette_rect().grow(-22.0)
	var raw_aspect := bounds.size.x / maxf(0.001, bounds.size.y)
	var fit_width: float = bounds.size.x * scale
	var fit_height: float = bounds.size.y * scale
	if fit_width - rect.size.x > 0.5 or fit_height - rect.size.y > 0.5:
		_fail("Silhouette does not letterbox into panel with a uniform scale.")
	var mapped_a: Vector2 = view._map_local_point(bounds.position)
	var mapped_b: Vector2 = view._map_local_point(bounds.position + bounds.size)
	var mapped_aspect := absf(mapped_b.x - mapped_a.x) / maxf(0.001, absf(mapped_b.y - mapped_a.y))
	if absf(mapped_aspect - raw_aspect) > 0.02:
		_fail("Power panel model uses non-uniform aspect: raw %.3f mapped %.3f" % [raw_aspect, mapped_aspect])
	print("POWER_ALLOCATION_PANEL_MODEL_ASPECT_PROBE ok aspect=%.3f scale=%.3f" % [raw_aspect, scale])
	quit()
