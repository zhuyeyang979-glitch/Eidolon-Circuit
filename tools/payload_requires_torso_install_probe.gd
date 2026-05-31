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


func _module_index(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = Dictionary(main._catalog_for("hero", "module")[i])
		if String(part.get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _board_pos(main, unit_bp: Dictionary, node_index: int) -> Vector2:
	var nodes: Array = Array(Dictionary(unit_bp.get("custom_topology", {})).get("nodes", []))
	if node_index < 0 or node_index >= nodes.size():
		return Vector2.ZERO
	return main._topology_position_to_board_local(main._topology_node_position(Dictionary(nodes[node_index])))


func _click_catalog_entry(main, slot_key: String, part_index: int) -> void:
	main.editor_slot_index = MainScene.BUILD_SLOTS.find(slot_key)
	main.editor_part_group_mode = "software" if slot_key in ["special", "module"] else "software_muscle"
	main.editor_part_filter_mode = slot_key
	main.editor_catalog_page = 0
	var entries: Array = main._editor_catalog_entries("hero", slot_key)
	for i in range(entries.size()):
		var entry: Dictionary = Dictionary(entries[i])
		if String(entry.get("slot", "")) == slot_key and int(entry.get("index", -1)) == part_index:
			main.editor_catalog_page = int(i / maxi(1, main.editor_catalog_buttons.size()))
			main._select_catalog_component(i % maxi(1, main.editor_catalog_buttons.size()))
			return
	_fail("Catalog entry not found for %s[%d]." % [slot_key, part_index])


func _make_two_torso_unit(main, torso_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso_a: int = main._append_component_root_node(nodes, "CORE A", Vector2(0.35, 0.5), torso_index)
	var torso_b: int = main._append_component_root_node(nodes, "CORE B", Vector2(0.65, 0.5), torso_index)
	if torso_a != 0 or torso_b != 1:
		_fail("Unexpected torso node indices.")
	unit_bp["blank_canvas"] = false
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_canvas_mode = "blank"

	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part) and int(part.get("module_slots", 0)) >= 2)
	var engine_index := _find(main, "engine", func(_part: Dictionary) -> bool: return true)
	var booster_index := _find(main, "booster", func(_part: Dictionary) -> bool: return true)
	var module_index := _module_index(main)
	if torso_index < 0 or engine_index < 0 or booster_index < 0 or module_index < 0:
		_fail("Missing torso, engine, booster, or module fixture.")
	var unit_bp := _make_two_torso_unit(main, torso_index)
	main.editor_working_blueprint = unit_bp
	main.editor_topology_node_index = 0
	main.editor_open_torso_node_index = -1

	_click_catalog_entry(main, "engine", engine_index)
	if Array(unit_bp.get("slot_payloads", [])).size() != 0:
		_fail("Catalog click installed engine before selecting a torso.")
	if main.editor_pending_payload_slot != "engine" or main.editor_pending_payload_index != engine_index:
		_fail("Catalog click did not create pending engine payload.")
	if not String(main.editor_summary_label.text).contains("待安装") and not String(main.editor_summary_label.text).contains("Pending install"):
		_fail("Pending engine did not use pending-install feedback: %s" % String(main.editor_summary_label.text))

	main._install_pending_payload_part_on_board(Vector2(8.0, 8.0))
	if Array(unit_bp.get("slot_payloads", [])).size() != 0:
		_fail("Clicking empty board installed pending engine.")
	if main.editor_pending_payload_slot != "engine":
		_fail("Failed pending engine install should keep pending state.")

	var torso_a_pos := _board_pos(main, unit_bp, 0)
	main._install_pending_payload_part_on_board(torso_a_pos)
	var payloads: Array = Array(unit_bp.get("slot_payloads", []))
	if payloads.size() != 1 or int(Dictionary(payloads[0]).get("torso_node", -1)) != 0:
		_fail("Engine did not install exactly once on torso A: %s" % str(payloads))
	if main.editor_pending_payload_slot != "":
		_fail("Successful engine install did not clear pending payload.")

	var torso_b_pos := _board_pos(main, unit_bp, 1)
	main._drop_catalog_part_on_board("booster", booster_index, torso_b_pos)
	payloads = Array(unit_bp.get("slot_payloads", []))
	if payloads.size() != 2 or int(Dictionary(payloads[1]).get("torso_node", -1)) != 1:
		_fail("Booster drop did not install on torso B: %s" % str(payloads))

	main._drop_catalog_part_on_board("booster", booster_index, Vector2(12.0, 12.0))
	payloads = Array(unit_bp.get("slot_payloads", []))
	if payloads.size() != 2:
		_fail("Booster drop on empty board should not install: %s" % str(payloads))
	if main.editor_pending_payload_slot != "booster":
		_fail("Failed booster drop should leave pending booster.")

	main._clear_pending_payload_part()
	_click_catalog_entry(main, "module", module_index)
	if not main.editor_pending_module_binding.is_empty():
		_fail("Catalog click started module binding before torso install.")
	if Array(unit_bp.get("slot_payloads", [])).size() != 2:
		_fail("Catalog module click changed payload count.")
	main._install_pending_payload_part_on_board(torso_a_pos)
	payloads = Array(unit_bp.get("slot_payloads", []))
	if payloads.size() != 3 or int(Dictionary(payloads[2]).get("torso_node", -1)) != 0:
		_fail("Module did not install once on torso A: %s" % str(payloads))
	if main.editor_pending_module_binding.is_empty():
		_fail("Module binding did not start after actual torso install.")
	if int(main.editor_pending_module_binding.get("payload_index", -1)) != 2:
		_fail("Module binding points at wrong payload index.")

	print("PAYLOAD_REQUIRES_TORSO_INSTALL_PROBE ok payloads=%d" % payloads.size())
	quit()
