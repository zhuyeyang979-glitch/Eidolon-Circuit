extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_torso_with_plugin_slot(main, required_rank: int) -> int:
	for i in range(MainScene.COMMON_CATALOG["muscle"].size()):
		var part: Dictionary = MainScene.COMMON_CATALOG["muscle"][i]
		if not main._component_is_torso(part):
			continue
		if main._torso_plugin_capacity_for_part(part) <= 0:
			continue
		for raw_rank in main._torso_internal_slot_size_ranks(part):
			if int(raw_rank) >= required_rank:
				return i
	return -1


func _shield_payload_indices(main) -> Dictionary:
	var result := {}
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		if not (catalog[i] is Dictionary):
			continue
		var part: Dictionary = catalog[i]
		if bool(part.get("shield_payload", false)) or bool(part.get("electronic_armor", false)) or String(part.get("material_class", "")).to_lower() == "shield_payload":
			result[String(part.get("name", ""))] = i
	return result


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var expected_ranks := {
		"SHIELD VEIL PATCH": 2.0,
		"SHIELD DUEL HALO": 3.0,
		"SHIELD SIEGE MANTLE": 4.0,
		"SHIELD TITAN DOME": 5.0,
	}
	var shield_indices := _shield_payload_indices(main)
	if shield_indices.size() != expected_ranks.size():
		_fail("Expected %d shield payloads, found %d: %s" % [expected_ranks.size(), shield_indices.size(), str(shield_indices.keys())])
		return
	for shield_name in expected_ranks.keys():
		if not shield_indices.has(shield_name):
			_fail("Missing shield payload: %s" % shield_name)
			return
		var raw_part: Dictionary = MainScene.COMMON_CATALOG["muscle"][int(shield_indices[shield_name])]
		if float(raw_part.get("length", -1.0)) != 0.0 or float(raw_part.get("radius", -1.0)) != 0.0 or int(raw_part.get("connection_ends", -1)) != 0:
			_fail("%s raw catalog should have no combat geometry: %s" % [shield_name, str(raw_part)])
			return
		var part: Dictionary = main._selected_component("hero", "muscle", int(shield_indices[shield_name]))
		for hp_key in ["hp", "health", "max_hp"]:
			if part.has(hp_key):
				_fail("%s exposes part HP field %s after normalization." % [shield_name, hp_key])
				return
		if main._component_has_combat_volume(part, "muscle"):
			_fail("%s reports combat volume." % shield_name)
			return
		var rank := main._part_slot_volume_rank(part, "muscle")
		if absf(rank - float(expected_ranks[shield_name])) > 0.001:
			_fail("%s slot volume rank expected %.1f, got %.1f." % [shield_name, float(expected_ranks[shield_name]), rank])
			return
		var payload_rank := main._payload_slot_volume_rank("electronic_armor", part, {"kind": "electronic_armor", "muscle": int(shield_indices[shield_name])}, "muscle")
		if absf(payload_rank - rank) > 0.001:
			_fail("%s payload rank %.1f did not match part rank %.1f." % [shield_name, payload_rank, rank])
			return
	var install_name := "SHIELD VEIL PATCH"
	var install_index := int(shield_indices[install_name])
	var install_part: Dictionary = main._selected_component("hero", "muscle", install_index)
	var install_rank := int(main._part_slot_volume_rank(install_part, "muscle"))
	var torso_index := _find_torso_with_plugin_slot(main, install_rank)
	if torso_index < 0:
		_fail("No torso has a plugin slot for shield rank %d." % install_rank)
		return
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, "muscle", torso_index)
	var torso_node: int = main._add_topology_node_at(Vector2(500.0, 302.0))
	if torso_node < 0:
		_fail("Could not place torso for shield payload install.")
		return
	main._open_editor_torso_detail(torso_node)
	main._drop_catalog_part_on_torso_detail("muscle", install_index, "plugin")
	var payloads: Array = Array(unit_bp.get("slot_payloads", []))
	if payloads.size() != 1 or not (payloads[0] is Dictionary):
		_fail("Shield install should create one torso payload, got %d." % payloads.size())
		return
	var payload: Dictionary = payloads[0]
	if String(payload.get("kind", "")) != "electronic_armor":
		_fail("Shield payload kind should be electronic_armor, got %s." % String(payload.get("kind", "")))
		return
	if int(payload.get("torso_node", -1)) != torso_node or int(payload.get("internal_slot_index", -1)) < 0:
		_fail("Shield payload should occupy a torso plugin slot: %s" % str(payload))
		return
	var plugins: Array = main._torso_plugin_slot_summary(unit_bp, torso_node)
	if plugins.size() != 1:
		_fail("Expected one plugin summary entry for shield payload, got %d." % plugins.size())
		return
	var label := String(Dictionary(plugins[0]).get("payload_size_label", ""))
	if label != main._volume_rank_label(float(install_rank)):
		_fail("Shield plugin size label expected %s, got %s." % [main._volume_rank_label(float(install_rank)), label])
		return
	var stats: Dictionary = main._compute_unit_stats(main._editor_player(), "hero", -1, unit_bp)
	if int(stats.get("slot_payload_count", 0)) != 1 or float(stats.get("slot_payload_volume_rank", 0.0)) < float(install_rank):
		_fail("Shield payload should count as internal payload volume: count=%s volume=%s" % [str(stats.get("slot_payload_count", "")), str(stats.get("slot_payload_volume_rank", ""))])
		return
	print("SHIELD_PAYLOAD_SLOT_VOLUME_PROBE ok ranks=%s installed=%s" % [str(expected_ranks), label])
	quit(0)
