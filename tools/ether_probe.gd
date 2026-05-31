extends SceneTree

const MainScene := preload("res://scripts/main.gd")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _special_index(role_key: String, item_name: String) -> int:
	var catalog: Array = MainScene.SPECIAL_CATALOG[role_key]
	for i in range(catalog.size()):
		if String(Dictionary(catalog[i]).get("name", "")) == item_name:
			return i
	return -1


func _barrier_bp(special_index: int, extra_ethers: Array = []) -> Dictionary:
	return {
		"name": "Vector Ether Probe",
		"archetype": "custom",
		"special": special_index,
		"joint": 30,
		"limb_muscle": 0,
		"muscle": 14,
		"booster": 0,
		"engine": 0,
		"cooling": 5,
		"module": 10,
		"ether_group": extra_ethers,
		"barrier_tiles": [
			{"index": 12, "joint": 30},
			{"index": 13, "joint": 31},
		],
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()

	var right_index := _special_index("barrier", "ETHER A: VECTOR RIGHT GRAVITY")
	var left_index := _special_index("barrier", "ETHER B: VECTOR LEFT GRAVITY")
	var up_index := _special_index("barrier", "ETHER C: VECTOR UP GRAVITY")
	var down_index := _special_index("barrier", "ETHER D: VECTOR DOWN GRAVITY")
	if mini(right_index, mini(left_index, mini(up_index, down_index))) < 0:
		_fail("Vector ether catalog entries are missing.")

	main.blueprints[1]["barrier"] = [_barrier_bp(right_index)]
	var stats: Dictionary = main._compute_unit_stats(1, "barrier", 0)
	print("ETHER_SINGLE count=%d cap=%d bind=%.1f dir=%s force=%.2f slots=%d" % [
		int(stats.get("ether_count", 0)),
		int(stats.get("ether_group_capacity", 0)),
		float(stats.get("ether_bind_radius_m", 0.0)),
		String(stats.get("gravity_direction", "")),
		float(stats.get("gravity_force", 0.0)),
		int(stats.get("material_slots", 0)),
	])
	if int(stats.get("ether_count", 0)) != 1:
		_fail("Single vector ether did not merge as one ether.")
	if String(stats.get("gravity_direction", "")) != "right":
		_fail("Right vector ether did not preserve its gravity direction.")
	if String(stats.get("barrier_logic", "")) != "gravity_vector":
		_fail("Vector ether did not preserve gravity_vector barrier logic.")

	main.blueprints[1]["barrier"] = [_barrier_bp(right_index, [up_index, down_index])]
	var group_stats: Dictionary = main._compute_unit_stats(1, "barrier", 0)
	print("ETHER_GROUP count=%d cap=%d bind=%.1f slots=%d effects=%d kind=%s" % [
		int(group_stats.get("ether_count", 0)),
		int(group_stats.get("ether_group_capacity", 0)),
		float(group_stats.get("ether_bind_radius_m", 0.0)),
		int(group_stats.get("material_slots", 0)),
		Array(group_stats.get("ether_effects", [])).size(),
		String(group_stats.get("ether_group_kind", "")),
	])
	if int(group_stats.get("ether_count", 0)) != 3:
		_fail("Ether group did not include primary plus extra ethers.")
	if Array(group_stats.get("ether_effects", [])).size() != 3:
		_fail("Ether group did not keep all gravity effects.")

	main.blueprints[1]["barrier"] = [_barrier_bp(right_index, [up_index, down_index, left_index])]
	var illegal_stats: Dictionary = main._compute_unit_stats(1, "barrier", 0)
	var illegal_note := main._topology_rule_note(main._blueprint_for(1, "barrier", 0), "barrier", illegal_stats)
	print("ETHER_ILLEGAL count=%d cap=%d note=%s" % [
		int(illegal_stats.get("ether_count", 0)),
		int(illegal_stats.get("ether_group_capacity", 0)),
		illegal_note,
	])
	if not illegal_note.begins_with("INVALID: ether group"):
		_fail("Oversized ether group did not produce an invalid topology note.")

	main.blueprints[1]["barrier"] = [_barrier_bp(right_index)]
	stats = main._compute_unit_stats(1, "barrier", 0)
	var barrier = main._create_unit(1, "barrier", stats, "RIGHT ETHER", 4.0, 0.0)
	main.active_units[1]["barrier"] = barrier
	var enemy_stats: Dictionary = main._compute_unit_stats(2, "hero", 0)
	enemy_stats["health"] = 100
	var tile_pos := Vector2(4.2, 0.0)
	var tiles: Array = Array(barrier.stats.get("barrier_map_tiles", []))
	if not tiles.is_empty() and tiles[0] is Dictionary:
		tile_pos = main._barrier_tile_world_position(barrier, Dictionary(tiles[0]), true)
	var enemy = main._create_unit(2, "hero", enemy_stats, "TARGET", tile_pos.x + 0.05, tile_pos.y)
	main.active_units[2]["hero"] = enemy
	main._apply_gravity_field(barrier, 1, 1.0)
	print("ETHER_GRAVITY target_velocity=%s" % [str(enemy.velocity)])
	if enemy.velocity.x <= 0.0:
		_fail("Right vector ether did not accelerate target to the right.")
	quit()
