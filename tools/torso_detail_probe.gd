extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_torso(main) -> int:
	for i in range(MainScene.COMMON_CATALOG["muscle"].size()):
		var part: Dictionary = MainScene.COMMON_CATALOG["muscle"][i]
		if main._component_is_torso(part) and int(part.get("module_slots", 0)) > 0:
			return i
	return -1


func _find_ammo() -> int:
	for i in range(MainScene.COMMON_CATALOG["muscle"].size()):
		var part: Dictionary = MainScene.COMMON_CATALOG["muscle"][i]
		if bool(part.get("ammo_slot_payload", false)) or String(part.get("material_class", "")) == "ammo_payload":
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
	var torso_index := _find_torso(main)
	if torso_index < 0:
		_fail("No torso part with software slots found.")
	main._set_pending_canvas_part(unit_bp, "muscle", torso_index)
	var torso_node: int = main._add_topology_node_at(Vector2(500.0, 302.0))
	if torso_node < 0:
		_fail("Could not place torso on canvas.")
	main._open_editor_torso_detail(torso_node)
	if main.editor_open_torso_node_index != torso_node or not main.editor_torso_detail_view.visible:
		_fail("Torso detail panel did not open for the selected torso.")
	var torso_part: Dictionary = MainScene.COMMON_CATALOG["muscle"][torso_index]
	var plugin_cap := main._torso_plugin_capacity_for_part(torso_part)
	var software_cap := main._torso_software_capacity_for_part(torso_part)
	if plugin_cap < 3 or software_cap < 3:
		_fail("Torso baseline slot capacity is too low: plugin=%d software=%d." % [plugin_cap, software_cap])
	if main.editor_torso_detail_view.plugin_capacity != plugin_cap or main.editor_torso_detail_view.software_capacity != software_cap:
		_fail("Torso detail panel did not use normalized slot capacities.")
	if main.editor_torso_detail_view.plugin_entries.size() != plugin_cap:
		_fail("Torso detail panel did not expand plugin display entries to slot count.")
	if String(Dictionary(main.editor_torso_detail_view.plugin_entries[0]).get("slot_size_label", "")) == "":
		_fail("Torso detail plugin slot does not show a size badge.")
	main.editor_torso_detail_view.size = Vector2(420.0, 176.0)
	main._refresh_torso_detail_view()
	var max_plugin_scroll: float = main.editor_torso_detail_view._max_scroll("plugin")
	var max_software_scroll: float = main.editor_torso_detail_view._max_scroll("software")
	if plugin_cap > 3 and max_plugin_scroll <= 0.0:
		_fail("Plugin slots overflow but no plugin scrollbar range is available.")
	if software_cap > 3 and max_software_scroll <= 0.0:
		_fail("Software slots overflow but no software scrollbar range is available.")
	if max_plugin_scroll > 0.0:
		main.editor_torso_detail_view._scroll_group("plugin", 48.0)
		if main.editor_torso_detail_view.plugin_scroll <= 0.0:
			_fail("Plugin scrollbar did not scroll.")
	if max_software_scroll > 0.0:
		main.editor_torso_detail_view._drag_scrollbar_to("software", main.editor_torso_detail_view._scrollbar_track_rect("software").position.y + 20.0)
		if main.editor_torso_detail_view.software_scroll <= 0.0:
			_fail("Software scrollbar drag did not move.")
	var ammo_index := _find_ammo()
	if ammo_index < 0:
		_fail("No ammo payload found for plugin slot installation.")
	main.editor_ammo_size_rank = 1
	main._drop_catalog_part_on_torso_detail("muscle", ammo_index, "plugin", 1)
	main._drop_catalog_part_on_torso_detail("special", 0, "software")
	var payloads: Array = Array(unit_bp.get("slot_payloads", []))
	if payloads.size() != 2:
		_fail("Expected 2 torso payloads after plugin/software install, got %d." % payloads.size())
	for payload in payloads:
		if not (payload is Dictionary):
			_fail("Torso payload is not a dictionary.")
		if int(Dictionary(payload).get("torso_node", -1)) != torso_node:
			_fail("Torso payload was not attached to the opened torso node.")
	if not Dictionary(payloads[0]).has("internal_slot_index"):
		_fail("Plugin payload did not store an internal_slot_index.")
	var plugins: Array = main._torso_plugin_slot_summary(unit_bp, torso_node)
	var software: Array = main._torso_software_slot_summary(unit_bp, torso_node)
	if plugins.size() != 1 or software.size() != 1:
		_fail("Expected one plugin and one software entry, got plugin=%d software=%d." % [plugins.size(), software.size()])
	var stats: Dictionary = main._compute_unit_stats(main._editor_player(), "hero", -1, unit_bp)
	if int(stats.get("slot_payload_count", 0)) < 1 or int(stats.get("software_payload_count", 0)) < 1:
		_fail("Torso slot stats did not count installed plugin/software.")
	if String(stats.get("slot_payload_note", "")).contains("Payload"):
		_fail("Player-facing torso slot note still uses old Payload wording.")
	print("TORSO_DETAIL_PROBE torso=%d plugin=%d software=%d note=%s" % [
		torso_node,
		plugins.size(),
		software.size(),
		String(stats.get("slot_payload_note", "")),
	])
	quit()
