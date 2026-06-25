extends RefCounted
class_name StarSoulEntityService

const DEFAULT_HP_BY_BAND := {
	"low": 45,
	"medium": 80,
	"high": 130,
	"very_high": 180,
}
const DEFAULT_RADIUS_BY_BAND := {
	"low": 0.34,
	"medium": 0.44,
	"high": 0.56,
	"very_high": 0.72,
}
const DEFAULT_DAMAGE_BY_BAND := {
	"none": 0,
	"low": 4,
	"medium": 7,
	"high": 11,
}
const DEFAULT_RANGE_BY_BAND := {
	"contact": 0.36,
	"melee": 0.48,
	"small": 0.88,
	"medium": 1.32,
	"large": 1.88,
	"aura": 1.18,
	"area": 1.12,
}


func spawn_payload(spawn_intent: Dictionary, context: Dictionary = {}, catalog_by_id: Dictionary = {}) -> Dictionary:
	var entry: Dictionary = Dictionary(spawn_intent.get("entry", {})).duplicate(true)
	if entry.is_empty():
		entry = spawn_intent.duplicate(true)
	var star_soul_id := String(entry.get("star_soul_id", spawn_intent.get("star_soul_id", ""))).strip_edges()
	if star_soul_id == "":
		return {"valid": false, "error": "missing_star_soul_id"}
	var owner := _safe_player(int(entry.get("owner", spawn_intent.get("owner", 1))))
	var catalog_entry: Dictionary = _catalog_entry(star_soul_id, catalog_by_id)
	var relation := String(catalog_entry.get("spawn_relation", entry.get("spawn_relation", "midfield")))
	var spawn := spawn_position(relation, owner, context)
	var stats := _stats_for(entry, catalog_entry, context)
	var sequence_index := int(entry.get("sequence_index", spawn_intent.get("sequence_index", 0)))
	var runtime_id := String(entry.get("runtime_id", spawn_intent.get("runtime_id", "star_soul_%03d" % (sequence_index + 1))))
	return {
		"valid": true,
		"owner": owner,
		"role": "star_soul",
		"name": _unit_name(owner, star_soul_id, catalog_entry),
		"ring": float(spawn.get("ring", 0.0)),
		"lane": float(spawn.get("lane", 0.0)),
		"stats": stats,
		"meta": {
			"star_soul": true,
			"star_soul_id": star_soul_id,
			"star_soul_runtime_id": runtime_id,
			"star_soul_sequence_index": sequence_index,
			"star_soul_owner": owner,
			"star_soul_vp": int(stats.get("vp", 0)),
			"star_soul_duration_remaining": float(stats.get("duration", 0.0)),
			"star_soul_spawn_relation": relation,
			"star_soul_movement": String(stats.get("star_soul_movement", "stationary")),
		},
		"catalog_entry": catalog_entry,
	}


func spawn_position(spawn_relation: String, owner: int, context: Dictionary = {}) -> Dictionary:
	var ring_length := maxf(0.001, float(context.get("ring_length", 24.0)))
	var half_height := maxf(0.001, float(context.get("battle_half_height", 7.5)))
	var safe_owner := _safe_player(owner)
	var opponent := 1 if safe_owner == 2 else 2
	var owner_spawn := _spawn_point(safe_owner, context, ring_length)
	var opponent_spawn := _spawn_point(opponent, context, ring_length)
	var relation := spawn_relation.strip_edges()
	var ring := float(owner_spawn.get("ring", 0.0))
	var lane := float(owner_spawn.get("lane", 0.0))
	match relation:
		"enemy_spawn":
			ring = float(opponent_spawn.get("ring", 0.0))
			lane = float(opponent_spawn.get("lane", 0.0))
		"midfield", "own_midfield":
			ring = wrapf(float(owner_spawn.get("ring", 0.0)) + ring_length * 0.25, 0.0, ring_length)
			lane = lerpf(float(owner_spawn.get("lane", 0.0)), float(opponent_spawn.get("lane", 0.0)), 0.5)
		"enemy_midfield":
			ring = wrapf(float(opponent_spawn.get("ring", 0.0)) + ring_length * 0.25, 0.0, ring_length)
			lane = lerpf(float(opponent_spawn.get("lane", 0.0)), float(owner_spawn.get("lane", 0.0)), 0.5)
		_:
			ring = float(owner_spawn.get("ring", 0.0))
			lane = float(owner_spawn.get("lane", 0.0))
	return {"ring": wrapf(ring, 0.0, ring_length), "lane": clampf(lane, -half_height, half_height)}


func _stats_for(entry: Dictionary, catalog_entry: Dictionary, context: Dictionary) -> Dictionary:
	var star_soul_id := String(entry.get("star_soul_id", catalog_entry.get("id", "")))
	var hp_band := String(catalog_entry.get("hp_band", "medium"))
	var damage_band := String(catalog_entry.get("damage_band", "low"))
	var range_band := String(catalog_entry.get("range_band", "small"))
	var movement := String(catalog_entry.get("movement", "stationary"))
	var hp := int(DEFAULT_HP_BY_BAND.get(hp_band, DEFAULT_HP_BY_BAND["medium"]))
	var radius := float(DEFAULT_RADIUS_BY_BAND.get(hp_band, DEFAULT_RADIUS_BY_BAND["medium"]))
	var mass := maxf(4.0, float(hp) * 0.42)
	var damage := int(DEFAULT_DAMAGE_BY_BAND.get(damage_band, DEFAULT_DAMAGE_BY_BAND["low"]))
	var attack_range := float(DEFAULT_RANGE_BY_BAND.get(range_band, DEFAULT_RANGE_BY_BAND["small"]))
	var duration := maxf(0.0, float(catalog_entry.get("duration", entry.get("duration", 0.0))))
	var owner := _safe_player(int(entry.get("owner", 1)))
	var stats := {
		"name": _unit_name(owner, star_soul_id, catalog_entry),
		"star_soul": true,
		"star_soul_id": star_soul_id,
		"star_soul_family": String(catalog_entry.get("family", "")),
		"star_soul_tier": String(catalog_entry.get("tier", "")),
		"star_soul_behavior": String(catalog_entry.get("behavior", "")),
		"star_soul_movement": movement,
		"star_soul_spawn_relation": String(catalog_entry.get("spawn_relation", "midfield")),
		"training_ball_dummy": true,
		"health": hp,
		"max_health": hp,
		"radius": radius,
		"length": radius * 2.0,
		"mass": mass,
		"structural_mass": mass,
		"speed": _movement_speed(movement),
		"boost_speed": 0.0,
		"turn_speed": 2.4,
		"normal_damage": damage,
		"active_damage": maxi(0, int(roundf(float(damage) * 1.25))),
		"armor_damage": maxi(0, int(roundf(float(damage) * 0.9))),
		"damage_type": "laser" if String(catalog_entry.get("family", "")).contains("tower") else "blunt",
		"range": attack_range,
		"active_range": attack_range,
		"hold_range": maxf(attack_range, 0.72),
		"source_keep_range": maxf(attack_range, 0.72),
		"ai": _ai_kind(movement),
		"sequence": ["normal"],
		"source_rules": _source_rules_for_movement(movement),
		"vp": maxi(0, int(entry.get("vp", catalog_entry.get("vp", 0)))),
		"duration": duration,
		"ally_buffs": Dictionary(catalog_entry.get("ally_buffs", {})).duplicate(true),
		"enemy_debuffs": Dictionary(catalog_entry.get("enemy_debuffs", {})).duplicate(true),
		"counter_tiers": {"bullet": 1, "chemical": 1, "laser": 1, "blunt": 1, "pierce": 1, "tear": 1},
		"resist": {"bullet": 1.0, "chemical": 1.0, "laser": 1.0, "blunt": 1.0, "pierce": 1.0, "tear": 1.0},
		"ammo_capacity": {"bullet": 0, "chemical": 0, "laser": 0},
		"primary_color": _player_color(context, owner, "primary_colors", Color(0.46, 0.9, 1.0, 1.0)),
		"accent_color": _player_color(context, owner, "accent_colors", Color(1.0, 0.78, 0.24, 1.0)),
	}
	var ally_buffs: Dictionary = Dictionary(catalog_entry.get("ally_buffs", {}))
	var enemy_debuffs: Dictionary = Dictionary(catalog_entry.get("enemy_debuffs", {}))
	if ally_buffs.has("economy_rate_mult"):
		stats["star_soul_economy_rate_mult"] = float(ally_buffs.get("economy_rate_mult", 1.0))
	if enemy_debuffs.has("owner_economy_rate_mult"):
		stats["star_soul_owner_economy_rate_mult"] = float(enemy_debuffs.get("owner_economy_rate_mult", 1.0))
	return stats


func _source_rules_for_movement(movement: String) -> Dictionary:
	var move := "hold"
	match movement:
		"move_to_enemy_spawn", "follow_nearest_enemy", "follow_nearest_any_unit":
			move = "hunt"
		"follow_nearest_ally":
			move = "hunt"
		"flee_from_any_unit":
			move = "retreat"
	return {
		"default": {"move": move, "modules": [0], "states": ["normal"]},
		"enemy_far": {"move": move, "modules": [0], "states": ["normal"]},
		"enemy_close": {"move": "retreat" if movement == "flee_from_any_unit" else move, "modules": [0], "states": ["normal"]},
	}


func _spawn_point(player: int, context: Dictionary, ring_length: float) -> Dictionary:
	var points: Dictionary = Dictionary(context.get("spawn_points", {}))
	var raw_point = points.get(player, points.get(str(player), {}))
	if raw_point is Vector2:
		return {"ring": float(raw_point.x), "lane": float(raw_point.y)}
	if raw_point is Dictionary:
		var point: Dictionary = raw_point
		return {"ring": float(point.get("ring", point.get("x", 0.0))), "lane": float(point.get("lane", point.get("y", 0.0)))}
	return {"ring": ring_length * 0.5 if player == 2 else 0.0, "lane": 0.0}


func _catalog_entry(star_soul_id: String, catalog_by_id: Dictionary) -> Dictionary:
	var raw_entry = catalog_by_id.get(star_soul_id, {})
	if raw_entry is Dictionary and not Dictionary(raw_entry).is_empty():
		return Dictionary(raw_entry).duplicate(true)
	return {"id": star_soul_id, "family": "unknown", "spawn_relation": "midfield", "movement": "stationary", "hp_band": "medium", "range_band": "small", "damage_band": "low", "duration": 50.0, "vp": 1}


func _player_color(context: Dictionary, player: int, key: String, fallback: Color) -> Color:
	var colors: Dictionary = Dictionary(context.get(key, {}))
	var raw_color = colors.get(player, colors.get(str(player), fallback))
	return raw_color if raw_color is Color else fallback


func _unit_name(owner: int, star_soul_id: String, catalog_entry: Dictionary) -> String:
	var family := String(catalog_entry.get("family", "star_soul")).to_upper()
	var tier := String(catalog_entry.get("tier", "")).to_upper()
	return "P%d %s %s" % [owner, family, tier] if tier != "" else "P%d %s" % [owner, star_soul_id.to_upper()]


func _movement_speed(movement: String) -> float:
	match movement:
		"stationary":
			return 0.0
		"move_to_enemy_spawn":
			return 0.72
		"follow_nearest_any_unit", "follow_nearest_enemy", "follow_nearest_ally":
			return 0.62
		"flee_from_any_unit":
			return 0.78
	return 0.36


func _ai_kind(movement: String) -> String:
	match movement:
		"stationary":
			return "stationary"
		"flee_from_any_unit":
			return "coward"
		"move_to_enemy_spawn":
			return "cart"
	return "star_soul"


func _safe_player(player: int) -> int:
	return 2 if player == 2 else 1
