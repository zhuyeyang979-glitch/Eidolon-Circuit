extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _find_duel_core(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("name", "")).to_upper().contains("HUMANOVA DUEL CORE"):
			return part
	return {}


func _find_duel_core_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("name", "")).to_upper().contains("HUMANOVA DUEL CORE"):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var raw_duel := _find_duel_core(main)
	if raw_duel.is_empty():
		_fail("No HUMANOVA DUEL CORE found.")
	var raw_plugin_base := int(raw_duel.get("torso_slots", -1))
	var raw_software_base := int(raw_duel.get("module_slots", -1))
	_expect(raw_plugin_base == 3, "Raw HUMANOVA DUEL CORE torso_slots should remain design base 3, got %d." % raw_plugin_base)
	_expect(raw_software_base == 6, "Raw HUMANOVA DUEL CORE module_slots should remain design base 6, got %d." % raw_software_base)
	var plugin_base := maxi(raw_plugin_base, main._torso_baseline_slot_capacity(raw_duel, "plugin"))
	var software_base := maxi(raw_software_base, main._torso_baseline_slot_capacity(raw_duel, "software"))
	var plugin_capacity := main._torso_plugin_capacity_for_part(raw_duel)
	var software_capacity := main._torso_software_capacity_for_part(raw_duel)
	_expect(plugin_capacity == plugin_base + 1, "Plugin helper capacity should be max(raw, baseline) +1.")
	_expect(software_capacity == software_base + 1, "Software helper capacity should be max(raw, baseline) +1.")
	var slot_sizes := main._torso_internal_slot_size_ranks(raw_duel)
	_expect(slot_sizes.size() == plugin_capacity, "Internal slot profile length should match helper capacity.")
	_expect(int(slot_sizes[slot_sizes.size() - 1]) == int(slot_sizes[slot_sizes.size() - 2]), "Extra internal tail slot must repeat the previous slot size.")
	_expect(int(slot_sizes[slot_sizes.size() - 1]) <= int(slot_sizes[0]), "Extra internal tail slot must not become a larger slot.")
	var torso_index := _find_duel_core_index(main)
	_expect(torso_index >= 0, "No HUMANOVA DUEL CORE index found.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var torso_node := main._append_component_root_node(nodes, "DUEL CORE CONTRACT", Vector2(0.5, 0.5), torso_index)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_canvas_mode = "blank"
	main.editor_open_torso_node_index = torso_node
	var stats := main._compute_unit_stats(main._editor_player(), "hero", -1, unit_bp)
	_expect(int(stats.get("torso_slots", -1)) == plugin_capacity, "Stats must use helper plugin capacity, not raw base or double +1.")
	_expect(int(stats.get("module_slots", -1)) == software_capacity, "Stats must use helper software capacity, not raw base or double +1.")
	var enriched := main._editor_fast_enriched_board_node("hero", unit_bp, nodes, [], torso_node)
	_expect(int(enriched.get("torso_slots", -1)) == plugin_capacity, "Topology display node must use helper plugin capacity exactly once.")
	_expect(int(enriched.get("module_slots", -1)) == software_capacity, "Topology display node must use helper software capacity exactly once.")
	_expect(main._torso_plugin_capacity_for_part(raw_duel) == plugin_capacity, "Raw catalog helper capacity must stay stable after topology enrichment.")
	print("TORSO_SLOT_CAPACITY_CONTRACT_PROBE raw=%d/%d base=%d/%d helper=%d/%d ok" % [raw_plugin_base, raw_software_base, plugin_base, software_base, plugin_capacity, software_capacity])
	quit()
