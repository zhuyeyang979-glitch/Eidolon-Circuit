extends RefCounted
class_name StarSoulBehaviorService

const DEFAULT_ATTACK_INTERVAL := 1.0
const DEFAULT_AREA_INTERVAL := 0.55
const DEFAULT_CONTACT_INTERVAL := 0.45
const DEFAULT_AURA_TIMER := 0.22


func tick_intent(context: Dictionary) -> Dictionary:
	var delta := maxf(0.0, float(context.get("delta", 0.0)))
	var ring_length := maxf(0.001, float(context.get("ring_length", 24.0)))
	var star_soul: Dictionary = Dictionary(context.get("star_soul", {}))
	var stats: Dictionary = Dictionary(star_soul.get("stats", {}))
	var timers: Dictionary = Dictionary(context.get("timers", {})).duplicate(true)
	var units := _live_units(Array(context.get("units", [])), int(star_soul.get("id", 0)))
	var events: Array = []
	var behavior := String(stats.get("star_soul_behavior", ""))
	match behavior:
		"shoot_enemy_in_range":
			events.append_array(_shoot_enemy_events(star_soul, stats, units, timers, delta, ring_length))
		"damage_enemy_in_area":
			events.append_array(_area_damage_events(star_soul, stats, units, timers, delta, ring_length))
		"lose_hp_when_units_in_area":
			events.append_array(_self_damage_when_units_in_area_events(star_soul, stats, units, timers, delta, ring_length))
		"attack_path_blockers":
			events.append_array(_contact_damage_events(star_soul, stats, units, timers, delta, ring_length))
		"retarget_after_attack":
			events.append_array(_melee_attack_events(star_soul, stats, units, timers, delta, ring_length, "any"))
		"attack_owner_units":
			events.append_array(_melee_attack_events(star_soul, stats, units, timers, delta, ring_length, "ally"))
		"attack_enemy_units":
			events.append_array(_melee_attack_events(star_soul, stats, units, timers, delta, ring_length, "enemy"))
	events.append_array(_aura_events(star_soul, stats, units, ring_length))
	return {"events": events, "timers": timers}


func _shoot_enemy_events(star_soul: Dictionary, stats: Dictionary, units: Array, timers: Dictionary, delta: float, ring_length: float) -> Array:
	var cooldown := maxf(0.0, float(timers.get("attack_cooldown", 0.0)) - delta)
	timers["attack_cooldown"] = cooldown
	if cooldown > 0.0:
		return []
	var target := _nearest_target(star_soul, units, ring_length, "enemy")
	if target.is_empty():
		return []
	timers["attack_cooldown"] = maxf(0.1, float(stats.get("star_soul_attack_interval", DEFAULT_ATTACK_INTERVAL)))
	return [_damage_event(star_soul, stats, target, "shot")]


func _area_damage_events(star_soul: Dictionary, stats: Dictionary, units: Array, timers: Dictionary, delta: float, ring_length: float) -> Array:
	var area_timers: Dictionary = Dictionary(timers.get("area_timers", {})).duplicate(true)
	var interval := maxf(0.1, float(stats.get("star_soul_area_interval", DEFAULT_AREA_INTERVAL)))
	var events: Array = []
	for target in _targets_in_range(star_soul, units, ring_length, "enemy"):
		var target_id := str(target.get("id", ""))
		if target_id == "":
			continue
		var timer := maxf(0.0, float(area_timers.get(target_id, 0.0)) - delta)
		if timer > 0.0:
			area_timers[target_id] = timer
			continue
		area_timers[target_id] = interval
		events.append(_damage_event(star_soul, stats, target, "area"))
	timers["area_timers"] = area_timers
	return events


func _self_damage_when_units_in_area_events(star_soul: Dictionary, stats: Dictionary, units: Array, timers: Dictionary, delta: float, ring_length: float) -> Array:
	if _targets_in_range(star_soul, units, ring_length, "any").is_empty():
		return []
	var area_timers: Dictionary = Dictionary(timers.get("area_timers", {})).duplicate(true)
	var source_id := str(star_soul.get("id", ""))
	var interval := maxf(0.1, float(stats.get("star_soul_area_interval", DEFAULT_AREA_INTERVAL)))
	var timer := maxf(0.0, float(area_timers.get(source_id, 0.0)) - delta)
	if timer > 0.0:
		area_timers[source_id] = timer
		timers["area_timers"] = area_timers
		return []
	area_timers[source_id] = interval
	timers["area_timers"] = area_timers
	return [_damage_event(star_soul, stats, star_soul, "self_area")]


func _contact_damage_events(star_soul: Dictionary, stats: Dictionary, units: Array, timers: Dictionary, delta: float, ring_length: float) -> Array:
	var contact_timers: Dictionary = Dictionary(timers.get("contact_timers", {})).duplicate(true)
	var interval := maxf(0.08, float(stats.get("star_soul_contact_interval", DEFAULT_CONTACT_INTERVAL)))
	var events: Array = []
	for target in _targets_in_range(star_soul, units, ring_length, "enemy"):
		var target_id := str(target.get("id", ""))
		if target_id == "":
			continue
		var timer := maxf(0.0, float(contact_timers.get(target_id, 0.0)) - delta)
		if timer > 0.0:
			contact_timers[target_id] = timer
			continue
		contact_timers[target_id] = interval
		events.append(_damage_event(star_soul, stats, target, "contact"))
	timers["contact_timers"] = contact_timers
	return events


func _melee_attack_events(star_soul: Dictionary, stats: Dictionary, units: Array, timers: Dictionary, delta: float, ring_length: float, relation: String) -> Array:
	var cooldown := maxf(0.0, float(timers.get("attack_cooldown", 0.0)) - delta)
	timers["attack_cooldown"] = cooldown
	if cooldown > 0.0:
		return []
	var target := _nearest_target(star_soul, units, ring_length, relation)
	if target.is_empty():
		return []
	timers["attack_cooldown"] = maxf(0.12, float(stats.get("star_soul_attack_interval", DEFAULT_ATTACK_INTERVAL)))
	return [_damage_event(star_soul, stats, target, "melee")]


func _aura_events(star_soul: Dictionary, stats: Dictionary, units: Array, ring_length: float) -> Array:
	var events: Array = []
	var ally_buffs: Dictionary = Dictionary(stats.get("ally_buffs", {}))
	if not ally_buffs.is_empty():
		for target in _targets_in_range(star_soul, units, ring_length, "ally"):
			events.append(_aura_event(star_soul, target, "ally_buff", ally_buffs))
	var enemy_debuffs: Dictionary = Dictionary(stats.get("enemy_debuffs", {}))
	if not enemy_debuffs.is_empty():
		for target in _targets_in_range(star_soul, units, ring_length, "enemy"):
			events.append(_aura_event(star_soul, target, "enemy_debuff", enemy_debuffs))
	return events


func _damage_event(star_soul: Dictionary, stats: Dictionary, target: Dictionary, source_kind: String) -> Dictionary:
	var base_damage := maxi(1, int(roundf(float(stats.get("normal_damage", 1)))))
	return {
		"type": "damage",
		"source_kind": source_kind,
		"source_id": int(star_soul.get("id", 0)),
		"source_owner": _safe_player(int(star_soul.get("owner", 1))),
		"target_id": int(target.get("id", 0)),
		"damage": base_damage,
		"damage_type": String(stats.get("damage_type", "laser")),
		"projectile_style": "beam" if source_kind == "shot" else "field",
	}


func _aura_event(star_soul: Dictionary, target: Dictionary, aura_kind: String, effects: Dictionary) -> Dictionary:
	return {
		"type": "aura",
		"aura_kind": aura_kind,
		"source_id": int(star_soul.get("id", 0)),
		"source_owner": _safe_player(int(star_soul.get("owner", 1))),
		"target_id": int(target.get("id", 0)),
		"effects": effects.duplicate(true),
		"timer": DEFAULT_AURA_TIMER,
	}


func _nearest_target(star_soul: Dictionary, units: Array, ring_length: float, relation: String) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for target in _targets_in_range(star_soul, units, ring_length, relation):
		var distance := _weighted_distance(star_soul, target, ring_length)
		if distance < best_distance:
			best_distance = distance
			best = target
	return best


func _targets_in_range(star_soul: Dictionary, units: Array, ring_length: float, relation: String) -> Array:
	var stats: Dictionary = Dictionary(star_soul.get("stats", {}))
	var range := maxf(0.0, float(stats.get("range", 0.0)))
	var owner := _safe_player(int(star_soul.get("owner", 1)))
	var result: Array = []
	for target in units:
		if not (target is Dictionary):
			continue
		var entry: Dictionary = target
		var target_owner := _safe_player(int(entry.get("owner", owner)))
		if relation == "enemy" and target_owner == owner:
			continue
		if relation == "ally" and target_owner != owner:
			continue
		var reach := range + maxf(0.0, float(entry.get("radius", 0.0)))
		if _weighted_distance(star_soul, entry, ring_length) <= reach:
			result.append(entry)
	return result


func _weighted_distance(a: Dictionary, b: Dictionary, ring_length: float) -> float:
	var dx := _ring_delta(float(a.get("ring", 0.0)), float(b.get("ring", 0.0)), ring_length)
	var dy := float(b.get("lane", 0.0)) - float(a.get("lane", 0.0))
	return absf(dx) + absf(dy) * 0.65


func _ring_delta(from_ring: float, to_ring: float, ring_length: float) -> float:
	var delta := to_ring - from_ring
	var half := ring_length * 0.5
	if delta > half:
		delta -= ring_length
	elif delta < -half:
		delta += ring_length
	return delta


func _live_units(units: Array, source_id: int) -> Array:
	var result: Array = []
	for raw_unit in units:
		if not (raw_unit is Dictionary):
			continue
		var unit: Dictionary = raw_unit
		if int(unit.get("id", 0)) == source_id:
			continue
		if not bool(unit.get("live", true)):
			continue
		result.append(unit)
	return result


func _safe_player(player: int) -> int:
	return 2 if player == 2 else 1
