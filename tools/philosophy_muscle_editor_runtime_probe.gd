extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _index(main, slot_key: String, item_name: String) -> int:
	var index: int = main._component_index_by_exact_name("hero", slot_key, item_name)
	if index < 0:
		_fail("Missing %s catalog part: %s" % [slot_key, item_name])
	return index


func _segment_for_name(segments: Array, item_name: String) -> Dictionary:
	for raw_segment in segments:
		if raw_segment is Dictionary and String(Dictionary(raw_segment).get("name", "")) == item_name:
			return Dictionary(raw_segment)
	return {}


func _assert_segment_field(segments: Array, item_name: String, key: String, expected) -> void:
	var segment := _segment_for_name(segments, item_name)
	if segment.is_empty():
		_fail("Missing runtime segment for %s." % item_name)
	if segment.get(key) != expected:
		_fail("%s segment %s expected %s, got %s." % [item_name, key, str(expected), str(segment.get(key))])


func _build_runtime_unit(main) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso_index := _index(main, "muscle", "SYNTAX MIDFIELD CORE")
	var limb_index := _index(main, "limb_muscle", "SYNTAX STANDARD LINK")
	var melee_index := _index(main, "muscle", "WAKIZASHI KATANA MUSCLE")
	var gun_name := "长视制式来复枪 / LONGSIGHT PATTERN RIFLE"
	var gun_index := _index(main, "muscle", gun_name)
	var barrier_index := _index(main, "muscle", "MAZE HARDLIGHT CAGE WALL PANEL")
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LINK", "limb_muscle", limb_index, Vector2.RIGHT)
	main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "KATANA", "muscle", melee_index, Vector2.RIGHT)
	var gun_limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "GUN-LINK", "limb_muscle", limb_index, Vector2.DOWN)
	main._append_directed_component_node("hero", unit_bp, nodes, edges, gun_limb, "RIFLE", "muscle", gun_index, Vector2.DOWN)
	main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "CAGE", "muscle", barrier_index, Vector2.LEFT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["unit_name"] = "Philosophy Muscle Runtime Probe"
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _barrier_index(main, item_name: String) -> int:
	var index: int = main._component_index_by_exact_name("barrier", "muscle", item_name)
	if index < 0:
		index = main._component_index_by_exact_name("hero", "muscle", item_name)
	if index < 0:
		_fail("Missing barrier muscle: %s" % item_name)
	return index


func _build_barrier_unit(main) -> Dictionary:
	return {
		"name": "Philosophy Barrier Runtime Probe",
		"archetype": "custom",
		"special": 0,
		"joint": 30,
		"limb_muscle": 0,
		"muscle": _barrier_index(main, "MAZE HARDLIGHT CAGE WALL PANEL"),
		"booster": 0,
		"engine": 0,
		"cooling": 5,
		"module": 10,
		"barrier_tiles": [
			{"index": 0, "muscle": _barrier_index(main, "MAZE HARDLIGHT CAGE WALL PANEL")},
			{"index": 2, "muscle": _barrier_index(main, "MAZE REPAIR DOCK FLOOR PANEL")},
			{"index": 4, "muscle": _barrier_index(main, "MAZE SPEED RAIL STRIP PANEL")},
		],
	}


func _assert_blueprint_stable(unit_bp: Dictionary) -> void:
	if unit_bp.has("attack_groups") or unit_bp.has("action_groups"):
		_fail("Philosophy muscle unit should not resurrect legacy attack/action groups.")
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	if Array(topology.get("nodes", [])).size() < 6 or Array(topology.get("edges", [])).size() < 5:
		_fail("Representative topology did not retain nodes and edges.")


func _assert_runtime_segments(stats: Dictionary) -> void:
	var segments: Array = Array(stats.get("runtime_topology_segments", []))
	if not bool(stats.get("teamedit_runtime_topology", false)) or segments.size() < 6:
		_fail("Custom topology did not generate runtime segments.")
	_assert_segment_field(segments, "SYNTAX MIDFIELD CORE", "catalog_role", "torso")
	_assert_segment_field(segments, "SYNTAX STANDARD LINK", "catalog_role", "limb")
	_assert_segment_field(segments, "WAKIZASHI KATANA MUSCLE", "weapon_family", "katana")
	_assert_segment_field(segments, "WAKIZASHI KATANA MUSCLE", "part_category", "melee:katana")
	var gun_name := "长视制式来复枪 / LONGSIGHT PATTERN RIFLE"
	_assert_segment_field(segments, gun_name, "catalog_role", "gun")
	_assert_segment_field(segments, gun_name, "gun_kind", "rifle")
	_assert_segment_field(segments, gun_name, "ammo_kind", "bullet")
	_assert_segment_field(segments, "MAZE HARDLIGHT CAGE WALL PANEL", "catalog_role", "barrier_tile")
	_assert_segment_field(segments, "MAZE HARDLIGHT CAGE WALL PANEL", "barrier_tile_component", true)
	var cage_segment := _segment_for_name(segments, "MAZE HARDLIGHT CAGE WALL PANEL")
	if not Array(cage_segment.get("barrier_effect_tags", [])).has("cage"):
		_fail("Barrier segment should preserve cage effect tag.")


func _assert_fighter_runtime(stats: Dictionary) -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "Philosophy Runtime",
		"stats": stats,
	})
	fighter.deploy(0.0, 0.0)
	if not bool(fighter.stats.get("teamedit_runtime_topology", false)):
		_fail("Fighter did not retain teamedit runtime topology flag.")
	var rifle := _segment_for_name(Array(fighter.stats.get("runtime_topology_segments", [])), "长视制式来复枪 / LONGSIGHT PATTERN RIFLE")
	if rifle.is_empty() or String(rifle.get("catalog_role", "")) != "gun":
		_fail("Fighter runtime stats did not retain gun segment role.")
	fighter.queue_free()


func _assert_barrier_runtime(main) -> void:
	var barrier_bp := _build_barrier_unit(main)
	var stats: Dictionary = main._compute_unit_stats(1, "barrier", -1, barrier_bp)
	var tiles: Array = Array(stats.get("barrier_map_tiles", []))
	if tiles.size() != 3:
		_fail("Barrier blueprint should generate three runtime tiles, got %d." % tiles.size())
	if not bool(stats.get("is_cage_wall", false)) or not bool(stats.get("is_repair_station", false)) or not bool(stats.get("is_speed_lane", false)):
		_fail("Barrier runtime stats did not retain cage/repair/speed flags.")
	var seen_tags := {}
	for raw_tile in tiles:
		if not (raw_tile is Dictionary):
			continue
		for raw_tag in Array(Dictionary(raw_tile).get("effect_tags", [])):
			seen_tags[String(raw_tag)] = true
	for tag in ["cage", "support", "speed_lane"]:
		if not bool(seen_tags.get(tag, false)):
			_fail("Barrier runtime tile missing %s tag." % tag)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit_bp := _build_runtime_unit(main)
	_assert_blueprint_stable(unit_bp)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	_assert_runtime_segments(stats)
	_assert_fighter_runtime(stats)
	_assert_barrier_runtime(main)
	print("PHILOSOPHY_MUSCLE_EDITOR_RUNTIME_PROBE ok segments=%d" % Array(stats.get("runtime_topology_segments", [])).size())
	quit()
