extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _build_single_torso(main, name: String) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	main._append_component_root_node(nodes, name, Vector2(0.5, 0.5), _first_torso(main))
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _min_gap(main, a, b) -> float:
	var best := INF
	var origin_x: float = a.ring_pos
	for raw_a in a.part_colliders():
		if not (raw_a is Dictionary):
			continue
		var collider_a: Dictionary = main._shift_collider_to_origin(Dictionary(raw_a), origin_x)
		for raw_b in b.part_colliders():
			if not (raw_b is Dictionary):
				continue
			var collider_b: Dictionary = main._shift_collider_to_origin(Dictionary(raw_b), origin_x)
			best = minf(best, main._collider_gap(collider_a, collider_b))
	return best


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var left_stats := main._compute_unit_stats(1, "hero", -1, _build_single_torso(main, "LEFT_CORE"))
	var right_stats := main._compute_unit_stats(2, "hero", -1, _build_single_torso(main, "RIGHT_CORE"))
	var left = FighterScene.new()
	var right = FighterScene.new()
	root.add_child(left)
	root.add_child(right)
	left._ready()
	right._ready()
	left.setup_unit({"unit_name": "NO_FX_LEFT", "owner_id": 1, "role": "hero", "stats": left_stats})
	right.setup_unit({"unit_name": "NO_FX_RIGHT", "owner_id": 2, "role": "hero", "stats": right_stats})
	left.deploy(5.0, 0.0)
	right.deploy(5.45, 0.72)
	left.velocity = Vector2(8.0, 0.0)
	right.velocity = Vector2(-8.0, 0.0)
	var gap := _min_gap(main, left, right)
	for attempt in range(80):
		if gap > 0.04:
			break
		right.lane += 0.08
		gap = _min_gap(main, left, right)
	if gap <= 0.0:
		_fail("Probe setup failed: units are touching, gap=%.4f" % gap)
	var left_hp: int = left.health
	var right_hp: int = right.health
	var before_effects: int = main.effects_root.get_child_count() if main.effects_root != null else 0
	main.battle_message = ""
	main.battle_message_timer = 0.0
	main._separate_unit_part_pair(left, right, 1.0 / 60.0)
	var after_effects: int = main.effects_root.get_child_count() if main.effects_root != null else 0
	if left.health != left_hp or right.health != right_hp:
		_fail("Pre-contact spacing changed HP: %d/%d -> %d/%d." % [left_hp, right_hp, left.health, right.health])
	if after_effects != before_effects:
		_fail("Pre-contact spacing spawned effects: %d -> %d, gap=%.4f." % [before_effects, after_effects, gap])
	if String(main.battle_message) != "":
		_fail("Pre-contact spacing displayed battle message: %s" % String(main.battle_message))
	print("RUNTIME_NO_PRECONTACT_FX_PROBE gap=%.4f effects=%d" % [gap, after_effects])
	quit()
