extends RefCounted
class_name BattleAwarenessService

const CLOSE_RESPONSE_POLICIES := ["kite", "retreat", "screen", "intercept"]


func live_count(unit_snapshots: Array) -> int:
	var count := 0
	for raw_unit in unit_snapshots:
		if raw_unit is Dictionary and bool(Dictionary(raw_unit).get("live", false)):
			count += 1
	return count


func first_live_id(unit_snapshots: Array, prefer_non_temporary: bool = false) -> int:
	if prefer_non_temporary:
		for raw_unit in unit_snapshots:
			if not (raw_unit is Dictionary):
				continue
			var unit: Dictionary = raw_unit
			if bool(unit.get("live", false)) and not bool(unit.get("temporary", false)):
				return int(unit.get("id", -1))
	for raw_unit in unit_snapshots:
		if raw_unit is Dictionary and bool(Dictionary(raw_unit).get("live", false)):
			return int(Dictionary(raw_unit).get("id", -1))
	return -1


func enemy_ids(player_id: int, unit_snapshots: Array) -> Array:
	var result: Array = []
	var enemy_id := 2 if player_id == 1 else 1
	for raw_unit in unit_snapshots:
		if not (raw_unit is Dictionary):
			continue
		var unit: Dictionary = raw_unit
		if bool(unit.get("live", false)) and int(unit.get("owner", 0)) == enemy_id:
			result.append(int(unit.get("id", -1)))
	return result


func friendly_ids(player_id: int, unit_snapshots: Array, include_self_id: int = -1) -> Array:
	var result: Array = []
	for raw_unit in unit_snapshots:
		if not (raw_unit is Dictionary):
			continue
		var unit: Dictionary = raw_unit
		var id := int(unit.get("id", -1))
		if bool(unit.get("live", false)) and int(unit.get("owner", 0)) == player_id and (include_self_id < 0 or id != include_self_id):
			result.append(id)
	return result


func nearest_candidate_id(candidates: Array) -> Dictionary:
	var best_id := -1
	var best_distance := 999999.0
	for raw_candidate in candidates:
		if not (raw_candidate is Dictionary):
			continue
		var candidate: Dictionary = raw_candidate
		var distance := float(candidate.get("distance", 999999.0))
		if distance < best_distance:
			best_distance = distance
			best_id = int(candidate.get("id", -1))
	return {"id": best_id, "distance": best_distance, "found": best_id >= 0}


func minimap_world_model(unit_snapshots: Array, camera_ring: float, camera_lane: float) -> Dictionary:
	return {
		"unit_points": minimap_points(unit_snapshots),
		"camera_ring": camera_ring,
		"camera_lane": camera_lane,
	}


func minimap_points(unit_snapshots: Array) -> Array:
	var points: Array = []
	for raw_unit in unit_snapshots:
		if not (raw_unit is Dictionary):
			continue
		var unit: Dictionary = raw_unit
		if not bool(unit.get("live", false)):
			continue
		var owner := int(unit.get("owner", 0))
		var tiles: Array = Array(unit.get("barrier_tiles", []))
		if not tiles.is_empty():
			for raw_tile in tiles:
				if not (raw_tile is Dictionary):
					continue
				var tile: Dictionary = raw_tile
				points.append({
					"ring": float(tile.get("ring", 0.0)),
					"lane": float(tile.get("lane", 0.0)),
					"owner": owner,
					"role": "space_debris" if bool(unit.get("space_debris", false)) else "barrier_piece",
					"radius": maxf(0.12, float(tile.get("radius", 0.12)) + float(tile.get("length", 0.2)) * 0.16),
				})
		else:
			points.append({
				"ring": float(unit.get("ring", 0.0)),
				"lane": float(unit.get("lane", 0.0)),
				"owner": owner,
				"role": String(unit.get("role", "unit")),
				"radius": float(unit.get("radius", 0.18)),
			})
	return points


func source_target_intent(context: Dictionary) -> Dictionary:
	var candidates: Array = Array(context.get("candidates", []))
	if candidates.is_empty():
		return {"target_id": -1, "found": false, "reason": "no_candidates", "score": 0.0}
	var threat_range := float(context.get("threat_range", 0.0))
	var close_response := String(context.get("close_response", ""))
	if threat_range > 0.0 and CLOSE_RESPONSE_POLICIES.has(close_response):
		var close := nearest_candidate_id(candidates)
		if bool(close.get("found", false)) and float(close.get("distance", 999999.0)) <= threat_range:
			close["target_id"] = int(close.get("id", -1))
			close["reason"] = "close_response"
			close["score"] = -float(close.get("distance", 0.0))
			return close
	var policy := String(context.get("policy", "nearest"))
	if policy == "" or policy == "nearest":
		var nearest := nearest_candidate_id(candidates)
		nearest["target_id"] = int(nearest.get("id", -1))
		nearest["reason"] = "nearest"
		nearest["score"] = -float(nearest.get("distance", 0.0))
		return nearest
	var best_id := -1
	var best_score := -999999.0
	for raw_candidate in candidates:
		if not (raw_candidate is Dictionary):
			continue
		var candidate: Dictionary = raw_candidate
		var score := source_target_score(candidate, policy)
		if score > best_score:
			best_score = score
			best_id = int(candidate.get("id", -1))
	if best_id >= 0:
		return {"target_id": best_id, "found": true, "reason": policy, "score": best_score}
	var fallback := nearest_candidate_id(candidates)
	fallback["target_id"] = int(fallback.get("id", -1))
	fallback["reason"] = "fallback_nearest"
	fallback["score"] = -float(fallback.get("distance", 0.0))
	return fallback


func source_target_score(facts: Dictionary, policy: String) -> float:
	var distance := float(facts.get("distance", 0.0))
	var hp_ratio := clampf(float(facts.get("hp_ratio", 1.0)), 0.0, 1.0)
	var target_role := String(facts.get("role", ""))
	var sight_blocked := bool(facts.get("sight_blocked", false))
	var score := -distance * 8.0 + (1.0 - hp_ratio) * 18.0
	if sight_blocked:
		score -= 30.0
	match policy:
		"heat_pressure_first":
			var heat_focus_ratio := clampf(float(facts.get("heat_focus_ratio", 0.68)), 0.0, 1.0)
			var heat_ratio := clampf(float(facts.get("heat_ratio", 0.0)), 0.0, 1.0)
			score += 240.0 if bool(facts.get("overheated", false)) else 0.0
			score += heat_ratio * (150.0 if heat_ratio >= heat_focus_ratio else 36.0)
			score += 42.0 if target_role == "hero" else 0.0
			score += 16.0 if target_role == "puppet" else 0.0
			score += 12.0 if target_role == "barrier" and bool(facts.get("support_barrier", false)) else 0.0
			score += (1.0 - hp_ratio) * 16.0
			score -= distance * 1.4
			score -= 48.0 if sight_blocked else 0.0
		"hero_low_hp_ranged":
			score += 120.0 if target_role == "hero" else 0.0
			score += (1.0 - hp_ratio) * 54.0
			score += 12.0 if target_role == "puppet" else 0.0
			score -= 42.0 if target_role == "barrier" else 0.0
			score -= distance * 2.5
			score -= 72.0 if sight_blocked else 0.0
		"low_hp_first":
			score += (1.0 - hp_ratio) * 118.0
			score += 22.0 if target_role == "hero" else 0.0
			score += 10.0 if target_role == "puppet" else 0.0
			score -= distance * 1.7
		"protect_hero":
			score += maxf(0.0, 80.0 - float(facts.get("hero_distance", 999999.0)) * 32.0)
			score += 36.0 if target_role == "hero" else 0.0
			score += 24.0 if float(facts.get("projectile_signal", 0.0)) > 0.0 else 0.0
		"protect_puppet_group":
			score += float(facts.get("group_threat_score", 0.0))
			score += 18.0 if float(facts.get("projectile_signal", 0.0)) > 0.0 else 0.0
			score += 10.0 if target_role == "puppet" else 0.0
			score -= 34.0 if target_role == "barrier" else 0.0
			score -= distance * 1.1
		"hero_siege":
			score += 180.0 if target_role == "hero" else 0.0
			score += 28.0 if target_role == "barrier" else 0.0
			score += (1.0 - hp_ratio) * 26.0
			score -= distance * 1.2
	return score
