extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main: Node, slot_key: String, predicate: Callable) -> int:
	var catalog: Array = main._catalog_for("hero", slot_key)
	for i in range(catalog.size()):
		if predicate.call(Dictionary(catalog[i])):
			return i
	return -1


func _place(main: Node, slot_key: String, part_index: int, pos: Vector2) -> int:
	main.editor_pending_place_slot = slot_key
	main.editor_pending_place_index = part_index
	var index := int(main._add_topology_node_at(main._topology_position_to_board_local(pos)))
	if index < 0:
		_fail("Failed to place %s #%d." % [slot_key, part_index])
		return -1
	return index


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	for key in ["auto_connect", "evaluate_connection", "restore_suggested_connection"]:
		if not main.editor_action_buttons.has(key):
			_fail("Missing connection action button: %s" % key)
			return
		var button: Button = main.editor_action_buttons[key]
		if not button.visible:
			_fail("Connection action should be visible for free-canvas body units: %s" % key)
			return
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool:
		return bool(part.get("is_torso", false))
	)
	var limb_index := _find(main, "limb_muscle", func(part: Dictionary) -> bool:
		return int(part.get("connection_ends", 0)) >= 2
	)
	var weapon_index := _find(main, "muscle", func(part: Dictionary) -> bool:
		return bool(part.get("terminal_weapon", false)) or int(part.get("connection_ends", 2)) <= 1
	)
	if torso_index < 0 or limb_index < 0 or weapon_index < 0:
		_fail("Probe could not find torso, limb, and weapon catalog parts.")
		return
	main._start_blank_topology()
	var torso_node := _place(main, "muscle", torso_index, Vector2(0.50, 0.50))
	var limb_node := _place(main, "limb_muscle", limb_index, Vector2(0.66, 0.50))
	var weapon_node := _place(main, "muscle", weapon_index, Vector2(0.84, 0.50))
	main._editor_action("evaluate_connection")
	if String(main.editor_connection_evaluation.get("state", "")) != "repairable":
		_fail("Disconnected beginner layout should be repairable, got %s." % str(main.editor_connection_evaluation))
		return
	main._editor_action("auto_connect")
	var topology: Dictionary = main._editor_current_blueprint().get("custom_topology", {})
	var edges: Array = topology.get("edges", [])
	if edges.size() < 2:
		_fail("Auto Connect should create at least two edges, got %d." % edges.size())
		return
	main._editor_action("evaluate_connection")
	if String(main.editor_connection_evaluation.get("state", "")) != "passed":
		_fail("Auto-connected beginner layout should pass, got %s." % str(main.editor_connection_evaluation))
		return
	main._unlink_joint_edges(main._editor_current_blueprint(), weapon_node)
	if String(main.editor_connection_evaluation.get("state", "")) != "stale":
		_fail("Manual unlink should mark connection evaluation stale.")
		return
	main._editor_action("restore_suggested_connection")
	main._editor_action("evaluate_connection")
	if String(main.editor_connection_evaluation.get("state", "")) != "passed":
		_fail("Restore Suggested followed by Evaluate should pass.")
		return
	print("UNIT_EDITOR_AUTO_CONNECTION_UI_PROBE ok torso=%d limb=%d weapon=%d" % [torso_node, limb_node, weapon_node])
	quit(0)
