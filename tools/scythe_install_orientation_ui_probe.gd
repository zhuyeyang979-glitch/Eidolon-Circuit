extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _scythe_index(main: Node) -> int:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._blade_weapon_family_for_part(part) == "scythe" and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var scythe_index := _scythe_index(main)
	if scythe_index < 0:
		_fail("Scythe terminal missing.")
		return
	main._drop_catalog_part_on_board("muscle", scythe_index, Vector2(310.0, 250.0))
	var pending := int(main.editor_pending_orientation_node_index)
	if pending < 0:
		_fail("Dropping a scythe did not start orientation choice.")
		return
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	if pending >= nodes.size() or not (nodes[pending] is Dictionary):
		_fail("Pending orientation node is invalid.")
		return
	var node: Dictionary = nodes[pending]
	if String(node.get("visual_mount_side", "")) != "right":
		_fail("Installed scythe should start with right mount side.")
		return
	if String(node.get("orientation_category", "")) != "orthogonal_side_mount":
		_fail("Installed scythe should expose orthogonal side-mount category.")
		return
	if not main.editor_action_buttons.has("set_handedness_left") or not bool(main.editor_action_buttons["set_handedness_left"].visible):
		_fail("Left blade choice button is not visible.")
		return
	if not main.editor_action_buttons.has("set_handedness_right") or not bool(main.editor_action_buttons["set_handedness_right"].visible):
		_fail("Right blade choice button is not visible.")
		return
	if main.editor_orientation_popup_panel == null or not bool(main.editor_orientation_popup_panel.visible):
		_fail("Side-mount popup is not visible after installing a scythe.")
		return
	main._editor_action("set_handedness_left")
	unit_bp = main._editor_current_blueprint()
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	node = nodes[pending]
	if String(node.get("visual_mount_side", "")) != "left":
		_fail("Left side-mount choice did not write visual_mount_side=left.")
		return
	if int(main.editor_pending_orientation_node_index) >= 0:
		_fail("Orientation choice should clear after choosing a side.")
		return
	main._editor_action("flip_handedness")
	unit_bp = main._editor_current_blueprint()
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	node = nodes[pending]
	if String(node.get("visual_mount_side", "")) != "right":
		_fail("Flip side action did not toggle the selected scythe.")
		return
	print("SCYTHE_INSTALL_ORIENTATION_UI_PROBE ok node=%d" % pending)
	quit()
