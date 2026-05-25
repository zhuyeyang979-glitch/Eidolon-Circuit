extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _capacity_total(capacity: Dictionary) -> int:
	var total := 0
	for ammo_type in MainScene.AMMO_TYPES:
		total += int(capacity.get(ammo_type, 0))
	return total


func _find_ammo_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._part_is_ammo_payload(part):
			return i
	return -1


func _find_torso_with_slot_rank(main, required_rank: int) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_torso(part):
			continue
		var ranks: Array = main._torso_internal_slot_size_ranks(part)
		for rank in ranks:
			if int(rank) >= required_rank:
				return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var ammo_index := _find_ammo_index(main)
	if ammo_index < 0:
		_fail("No ammo payload part found.")
	var torso_index := _find_torso_with_slot_rank(main, 2)
	if torso_index < 0:
		_fail("No torso with S internal slot found.")
	var ammo: Dictionary = main._selected_component("hero", "muscle", ammo_index)
	var base_cost := int(ammo.get("cost", 0))
	var base_mass := float(ammo.get("mass", 0.0))
	var base_total := _capacity_total(ammo.get("ammo_capacity", {}))
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var torso_node := main._append_component_root_node(nodes, "AMMO SIZE TEST CORE", Vector2(0.5, 0.5), torso_index)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_canvas_mode = "blank"
	main.editor_open_torso_node_index = torso_node
	main._set_editor_ammo_size_rank(2)
	main._add_torso_payload_component("muscle", ammo_index, ammo)
	var payloads: Array = unit_bp.get("slot_payloads", [])
	if payloads.size() != 1:
		_fail("Ammo install path did not add one payload: %s" % str(payloads))
	var payload: Dictionary = payloads[0]
	if String(payload.get("kind", "")) != "ammo":
		_fail("Installed payload kind is not ammo: %s" % str(payload))
	if String(payload.get("ammo_size_tier", "")) != "S":
		_fail("Installed payload did not store S ammo size tier: %s" % str(payload))
	var installed := main._payload_part_for_payload("hero", payload)
	if String(installed.get("ammo_size_tier", "")) != "S" or String(installed.get("slot_volume_tier", "")) != "S":
		_fail("Payload readback did not generate S ammo variant: %s" % str(installed))
	if int(installed.get("cost", 0)) != base_cost * 2:
		_fail("Installed ammo cost did not scale with S tier.")
	if not is_equal_approx(float(installed.get("mass", 0.0)), base_mass * 2.0):
		_fail("Installed ammo mass did not scale with S tier.")
	if _capacity_total(installed.get("ammo_capacity", {})) != base_total * 2:
		_fail("Installed ammo capacity did not scale with S tier.")
	print("AMMO_INSTALL_SIZE_PAYLOAD_PROBE tier=S total=%d ok" % _capacity_total(installed.get("ammo_capacity", {})))
	quit()
