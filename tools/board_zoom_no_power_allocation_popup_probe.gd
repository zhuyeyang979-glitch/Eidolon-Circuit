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
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "engine", "engine": engine_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = torso
	main._activate_engine_allocation_target_for_torso(unit_bp, torso)
	main._open_dashboard_engine_allocation()
	if main.engine_momentum_allocation_view == null or not main.engine_momentum_allocation_view.visible:
		_fail("Setup failed to open allocation panel.")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = Vector2(320.0, 240.0)
	main._handle_editor_board_zoom_wheel(wheel)
	if main.engine_momentum_allocation_view.visible:
		_fail("Board zoom left the fullscreen power allocation panel visible.")
	main._handle_editor_board_zoom_wheel(wheel)
	if main.engine_momentum_allocation_view.visible:
		_fail("Board zoom reopened the fullscreen power allocation panel.")
	print("BOARD_ZOOM_NO_POWER_ALLOCATION_POPUP_PROBE ok zoom=%.3f" % main.editor_board_zoom)
	quit()
