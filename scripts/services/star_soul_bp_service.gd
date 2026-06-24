extends RefCounted
class_name StarSoulBPService

const DEFAULT_PICKS_PER_PLAYER := 10
const DEFAULT_ANNOUNCE_SECONDS := 10.0
const DEFAULT_SCREEN_SIZE := Vector2(1.0, 1.0)


func battle_map_spec(player_screen_size: Vector2 = DEFAULT_SCREEN_SIZE) -> Dictionary:
	var screen := _safe_screen_size(player_screen_size)
	var circumference := screen.x * 2.0
	return {
		"topology": "mobius_strip",
		"circumference": circumference,
		"lane_height": screen.y * 1.5,
		"player_screen_size": screen,
		"spawn_separation": screen.x,
		"home_half_width": screen.x,
		"spawn_points": {
			1: Vector2(0.0, 0.0),
			2: Vector2(screen.x, 0.0),
		},
		"barrier_anchor": "owner_spawn",
		"barrier_initial_region": "owner_home_half",
	}


func spawn_point_for_player(player: int, player_screen_size: Vector2 = DEFAULT_SCREEN_SIZE) -> Vector2:
	var screen := _safe_screen_size(player_screen_size)
	return Vector2(screen.x, 0.0) if player == 2 else Vector2.ZERO


func point_in_home_half(x: float, player: int, player_screen_size: Vector2 = DEFAULT_SCREEN_SIZE) -> bool:
	var screen := _safe_screen_size(player_screen_size)
	var circumference := screen.x * 2.0
	var center := spawn_point_for_player(player, screen).x
	var delta := absf(_wrapped_delta(center, x, circumference))
	return delta <= screen.x * 0.5 + 0.0001


func draft_turns(first_player: int = 1, picks_per_player: int = DEFAULT_PICKS_PER_PLAYER) -> Array:
	var safe_picks := maxi(0, picks_per_player)
	var first := _safe_player(first_player)
	var second := opponent_player(first)
	var turns: Array = []
	for pick_index in range(safe_picks):
		turns.append({"turn": turns.size(), "player": first, "pick_index": pick_index})
		turns.append({"turn": turns.size(), "player": second, "pick_index": pick_index})
	return turns


func validate_draft(draft_picks: Array, first_player: int = 1, picks_per_player: int = DEFAULT_PICKS_PER_PLAYER, pool_ids: Array = []) -> Dictionary:
	var expected_turns := draft_turns(first_player, picks_per_player)
	var errors: Array = []
	var by_player := {1: [], 2: []}
	var picked := {}
	var pool_lookup := _lookup_from_array(pool_ids)
	if draft_picks.size() != expected_turns.size():
		errors.append("expected_%d_picks" % expected_turns.size())
	for turn_index in range(draft_picks.size()):
		var raw_pick = draft_picks[turn_index]
		if not (raw_pick is Dictionary):
			errors.append("pick_%d_not_dictionary" % turn_index)
			continue
		var pick: Dictionary = raw_pick
		var player := int(pick.get("player", 0))
		var star_soul_id := str(pick.get("star_soul_id", pick.get("id", ""))).strip_edges()
		if turn_index < expected_turns.size():
			var expected: Dictionary = expected_turns[turn_index]
			if player != int(expected.get("player", 0)):
				errors.append("pick_%d_wrong_player" % turn_index)
		if player != 1 and player != 2:
			errors.append("pick_%d_unknown_player" % turn_index)
			continue
		if star_soul_id == "":
			errors.append("pick_%d_missing_star_soul_id" % turn_index)
			continue
		if not pool_lookup.is_empty() and not bool(pool_lookup.get(star_soul_id, false)):
			errors.append("pick_%d_unknown_star_soul" % turn_index)
		if bool(picked.get(star_soul_id, false)):
			errors.append("pick_%d_duplicate_star_soul" % turn_index)
		picked[star_soul_id] = true
		by_player[player].append(star_soul_id)
	for player in [1, 2]:
		if Array(by_player[player]).size() != picks_per_player:
			errors.append("player_%d_expected_%d_picks" % [player, picks_per_player])
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"by_player": by_player,
		"expected_turns": expected_turns,
	}


func build_spawn_queue(draft_picks: Array, first_player: int = 1, picks_per_player: int = DEFAULT_PICKS_PER_PLAYER, options: Dictionary = {}) -> Dictionary:
	var validation := validate_draft(draft_picks, first_player, picks_per_player, Array(options.get("pool_ids", [])))
	if not bool(validation.get("valid", false)):
		return {"valid": false, "errors": validation.get("errors", []), "queue": []}
	var by_player: Dictionary = validation.get("by_player", {})
	var ordered_by_player := {
		1: _ordered_player_picks(Array(by_player.get(1, [])), 1, options),
		2: _ordered_player_picks(Array(by_player.get(2, [])), 2, options),
	}
	var first := _safe_player(first_player)
	var second := opponent_player(first)
	var owner_sequence: Array = []
	for _i in range(picks_per_player):
		owner_sequence.append(first)
		owner_sequence.append(second)
	var used_index := {1: 0, 2: 0}
	var queue: Array = []
	for sequence_index in range(owner_sequence.size()):
		var owner := int(owner_sequence[sequence_index])
		var owner_picks: Array = ordered_by_player.get(owner, [])
		var pick_index := int(used_index.get(owner, 0))
		if pick_index >= owner_picks.size():
			return {"valid": false, "errors": ["player_%d_queue_underflow" % owner], "queue": []}
		var star_soul_id := str(owner_picks[pick_index])
		used_index[owner] = pick_index + 1
		queue.append({
			"sequence_index": sequence_index,
			"owner": owner,
			"opponent": opponent_player(owner),
			"star_soul_id": star_soul_id,
			"announce_seconds": float(options.get("announce_seconds", DEFAULT_ANNOUNCE_SECONDS)),
		})
	return {"valid": true, "errors": [], "queue": queue}


func next_announcement(queue: Array, next_index: int) -> Dictionary:
	if next_index < 0 or next_index >= queue.size():
		return {"action": "complete"}
	var entry = queue[next_index]
	if not (entry is Dictionary):
		return {"action": "skip", "next_index": next_index + 1}
	var payload: Dictionary = Dictionary(entry).duplicate(true)
	payload["action"] = "announce"
	payload["countdown"] = float(payload.get("announce_seconds", DEFAULT_ANNOUNCE_SECONDS))
	return payload


func vp_award_for_exit(star_soul_owner: int, vp_value: int, exit_reason: String) -> Dictionary:
	if exit_reason != "destroyed":
		return {"award": false, "player": 0, "vp": 0, "reason": exit_reason}
	return {
		"award": true,
		"player": opponent_player(star_soul_owner),
		"vp": maxi(0, vp_value),
		"reason": exit_reason,
	}


func opponent_player(player: int) -> int:
	return 1 if _safe_player(player) == 2 else 2


func base_catalog() -> Array:
	return [
		_star_soul("defense_tower_a", "defense_tower", "A", "own_spawn", "stationary", "low", "shoot_enemy_in_range", "small", "low", 50.0, 1),
		_star_soul("defense_tower_b", "defense_tower", "B", "own_spawn", "stationary", "medium", "shoot_enemy_in_range", "medium", "medium", 40.0, 2),
		_star_soul("defense_tower_c", "defense_tower", "C", "own_spawn", "stationary", "high", "shoot_enemy_in_range", "large", "high", 30.0, 3),
		_star_soul("defense_tower_d", "defense_tower", "D", "midfield", "stationary", "high", "shoot_enemy_in_range", "small", "low", 50.0, 1, {"move_speed_mult": 1.5}),
		_star_soul("defense_tower_e", "defense_tower", "E", "midfield", "stationary", "high", "shoot_enemy_in_range", "medium", "medium", 40.0, 2, {"move_speed_mult": 1.5, "break_value_mult": 1.5}),
		_star_soul("defense_tower_f", "defense_tower", "F", "midfield", "stationary", "high", "shoot_enemy_in_range", "small", "low", 30.0, 3, {"move_speed_mult": 1.5, "break_value_mult": 1.5, "damage_mult": 1.5}),
		_star_soul("punishment_tower_a", "punishment_tower", "A", "enemy_spawn", "stationary", "high", "damage_enemy_in_area", "small", "low", 50.0, 1),
		_star_soul("punishment_tower_b", "punishment_tower", "B", "enemy_spawn", "stationary", "high", "damage_enemy_in_area", "large", "high", 40.0, 2),
		_star_soul("punishment_tower_c", "punishment_tower", "C", "enemy_spawn", "stationary", "high", "damage_enemy_in_area", "large", "high", 30.0, 3, {}, {"move_speed_mult": 0.5, "break_value_mult": 0.5, "damage_mult": 0.5}),
		_star_soul("punishment_tower_d", "punishment_tower", "D", "midfield", "stationary", "medium", "damage_enemy_in_area", "small", "low", 50.0, 1, {}, {"move_speed_mult": 0.5}),
		_star_soul("punishment_tower_e", "punishment_tower", "E", "midfield", "stationary", "high", "damage_enemy_in_area", "large", "high", 40.0, 2, {}, {"move_speed_mult": 0.5, "break_value_mult": 0.5}),
		_star_soul("punishment_tower_f", "punishment_tower", "F", "midfield", "stationary", "high", "damage_enemy_in_area", "large", "high", 30.0, 3, {"move_speed_mult": 1.5, "break_value_mult": 1.5, "damage_mult": 1.5}, {"move_speed_mult": 0.5, "break_value_mult": 0.5, "damage_mult": 0.5}),
		_star_soul("cart_a", "cart", "A", "own_spawn", "move_to_enemy_spawn", "medium", "attack_path_blockers", "contact", "medium", 0.0, 1, {"nearby_ally_speed_mult": 1.5}),
		_star_soul("wandering_giant_a", "wandering_giant", "A", "midfield", "follow_nearest_any_unit", "high", "retarget_after_attack", "melee", "medium", 50.0, 1),
		_star_soul("traitor_a", "traitor", "A", "own_spawn", "follow_nearest_ally", "high", "attack_owner_units", "melee", "low", 50.0, 1),
		_star_soul("loyalist_a", "loyalist", "A", "own_spawn", "follow_nearest_enemy", "medium", "attack_enemy_units", "melee", "low", 50.0, 1),
		_star_soul("rebel_a", "rebel", "A", "enemy_spawn", "follow_nearest_ally", "very_high", "attack_owner_units", "melee", "low", 50.0, 1),
		_star_soul("lord_a", "lord", "A", "own_spawn", "stationary", "medium", "owner_economy_buff", "aura", "none", 50.0, 1, {"economy_rate_mult": 1.2}),
		_star_soul("tyrant_a", "tyrant", "A", "own_spawn", "stationary", "very_high", "owner_economy_debuff", "aura", "none", 50.0, 1, {}, {"owner_economy_rate_mult": 0.8}),
		_star_soul("coward_a", "coward", "A", "midfield", "flee_from_any_unit", "medium", "lose_hp_when_units_in_area", "area", "none", 50.0, 1),
	]


func catalog_by_id() -> Dictionary:
	var result := {}
	for entry in base_catalog():
		if entry is Dictionary:
			result[str(Dictionary(entry).get("id", ""))] = Dictionary(entry).duplicate(true)
	return result


func _star_soul(
	id: String,
	family: String,
	tier: String,
	spawn_relation: String,
	movement: String,
	hp_band: String,
	behavior: String,
	range_band: String,
	damage_band: String,
	duration: float,
	vp: int,
	ally_buffs: Dictionary = {},
	enemy_debuffs: Dictionary = {}
) -> Dictionary:
	return {
		"id": id,
		"family": family,
		"tier": tier,
		"spawn_relation": spawn_relation,
		"movement": movement,
		"hp_band": hp_band,
		"behavior": behavior,
		"range_band": range_band,
		"damage_band": damage_band,
		"duration": duration,
		"vp": vp,
		"ally_buffs": ally_buffs.duplicate(true),
		"enemy_debuffs": enemy_debuffs.duplicate(true),
	}


func _ordered_player_picks(player_picks: Array, player: int, options: Dictionary) -> Array:
	var order_by_player: Dictionary = Dictionary(options.get("per_player_order", {}))
	var requested_order = order_by_player.get(player, order_by_player.get(str(player), []))
	if not (requested_order is Array) or Array(requested_order).is_empty():
		return player_picks.duplicate()
	var remaining := _lookup_from_array(player_picks)
	var ordered: Array = []
	for raw_id in Array(requested_order):
		var star_soul_id := str(raw_id)
		if bool(remaining.get(star_soul_id, false)):
			ordered.append(star_soul_id)
			remaining.erase(star_soul_id)
	for star_soul_id in player_picks:
		var id := str(star_soul_id)
		if bool(remaining.get(id, false)):
			ordered.append(id)
	return ordered


func _lookup_from_array(values: Array) -> Dictionary:
	var result := {}
	for value in values:
		var key := str(value).strip_edges()
		if key != "":
			result[key] = true
	return result


func _safe_player(player: int) -> int:
	return 2 if player == 2 else 1


func _safe_screen_size(player_screen_size: Vector2) -> Vector2:
	return Vector2(maxf(0.01, player_screen_size.x), maxf(0.01, player_screen_size.y))


func _wrapped_delta(from_x: float, to_x: float, circumference: float) -> float:
	if circumference <= 0.0:
		return to_x - from_x
	var delta := fmod(to_x - from_x, circumference)
	if delta > circumference * 0.5:
		delta -= circumference
	elif delta < -circumference * 0.5:
		delta += circumference
	return delta
