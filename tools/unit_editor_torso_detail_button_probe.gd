extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main.editor_panel_mode = "load"
	main._update_editor_ui()
	main._refresh_engine_allocation_dashboard_summary()
	if main.editor_torso_detail_button == null:
		_fail("Dedicated torso detail button was not created.")
	if not main.editor_torso_detail_button.visible:
		_fail("Dedicated torso detail button should stay visible in Unit Edit outside the parts panel.")
	if not main.editor_torso_detail_button.disabled:
		_fail("Dedicated torso detail button should be disabled before a torso exists.")
	var torso_part := _find_torso(main)
	if torso_part < 0:
		_fail("No torso part found.")
	main._set_pending_canvas_part(unit_bp, "muscle", torso_part)
	var torso_node: int = main._add_topology_node_at(Vector2(500.0, 302.0))
	if torso_node < 0:
		_fail("Could not place torso.")
	main._set_pending_canvas_part(unit_bp, "muscle", torso_part)
	var second_torso_node: int = main._add_topology_node_at(Vector2(610.0, 302.0))
	if second_torso_node < 0:
		_fail("Could not place second torso.")
	main.editor_topology_node_index = second_torso_node
	main.editor_panel_mode = "load"
	main._update_editor_ui()
	main._refresh_engine_allocation_dashboard_summary()
	if not main.editor_torso_detail_button.visible:
		_fail("Dedicated torso detail button is not visible in Unit Edit after placing a torso.")
	if main.editor_torso_detail_button.disabled:
		_fail("Dedicated torso detail button should be enabled after selecting a torso.")
	main._toggle_dashboard_torso_detail()
	if main.editor_torso_detail_view == null or not main.editor_torso_detail_view.visible:
		_fail("Dedicated torso detail button did not open the torso detail panel.")
	if main.editor_open_torso_node_index != second_torso_node:
		_fail("Torso detail should prefer selected torso: opened %d expected %d." % [main.editor_open_torso_node_index, second_torso_node])
	main._toggle_dashboard_torso_detail()
	if main.editor_torso_detail_view != null and main.editor_torso_detail_view.visible:
		_fail("Dedicated torso detail button did not close the torso detail panel on second click.")
	main.editor_topology_node_index = torso_node
	main._refresh_engine_allocation_dashboard_summary()
	main._toggle_dashboard_torso_detail()
	if main.editor_open_torso_node_index != torso_node:
		_fail("Torso detail button did not follow a changed selected torso: opened %d expected %d." % [main.editor_open_torso_node_index, torso_node])
	print("UNIT_EDITOR_TORSO_DETAIL_BUTTON_PROBE ok torso=%d second=%d" % [torso_node, second_torso_node])
	quit()
