extends SceneTree

const SERVICE_PATH := "res://scripts/services/star_soul_behavior_service.gd"

var failed := false


func _init() -> void:
	_require(FileAccess.file_exists(SERVICE_PATH), "Missing StarSoulBehaviorService script.")
	var ServiceScript = load(SERVICE_PATH)
	_require(ServiceScript != null, "Cannot load StarSoulBehaviorService.")
	if failed:
		quit(1)
		return
	var service = ServiceScript.new()
	var star_soul := {
		"id": 100,
		"owner": 1,
		"ring": 0.0,
		"lane": 0.0,
		"radius": 0.42,
		"stats": {
			"star_soul_behavior": "shoot_enemy_in_range",
			"range": 1.1,
			"normal_damage": 6,
			"damage_type": "laser",
			"star_soul_attack_interval": 1.0,
		},
	}
	var units := [
		{"id": 1, "owner": 1, "ring": 0.2, "lane": 0.0, "radius": 0.2, "live": true},
		{"id": 2, "owner": 2, "ring": 0.8, "lane": 0.0, "radius": 0.2, "live": true},
		{"id": 3, "owner": 2, "ring": 2.4, "lane": 0.0, "radius": 0.2, "live": true},
	]
	var shot: Dictionary = service.tick_intent({
		"delta": 0.1,
		"ring_length": 24.0,
		"star_soul": star_soul,
		"units": units,
		"timers": {"attack_cooldown": 0.0},
	})
	var events: Array = Array(shot.get("events", []))
	_require(events.size() == 1, "Defense tower should emit one shot event when an enemy is in range.")
	_require(String(Dictionary(events[0]).get("type", "")) == "damage", "Defense tower event should be damage.")
	_require(int(Dictionary(events[0]).get("target_id", 0)) == 2, "Defense tower should target the nearest enemy in range.")
	_require(float(Dictionary(shot.get("timers", {})).get("attack_cooldown", 0.0)) > 0.9, "Shot should reset tower attack cooldown.")

	var punishment := star_soul.duplicate(true)
	Dictionary(punishment["stats"])["star_soul_behavior"] = "damage_enemy_in_area"
	Dictionary(punishment["stats"])["range"] = 1.1
	Dictionary(punishment["stats"])["normal_damage"] = 5
	var area: Dictionary = service.tick_intent({
		"delta": 0.6,
		"ring_length": 24.0,
		"star_soul": punishment,
		"units": units,
		"timers": {"area_timers": {}},
	})
	var area_events: Array = Array(area.get("events", []))
	_require(area_events.size() == 1, "Punishment tower should damage each enemy inside area.")
	if not area_events.is_empty():
		_require(int(Dictionary(area_events[0]).get("target_id", 0)) == 2, "Punishment tower should not hit enemies outside area.")

	var aura := star_soul.duplicate(true)
	Dictionary(aura["stats"])["star_soul_behavior"] = "shoot_enemy_in_range"
	Dictionary(aura["stats"])["ally_buffs"] = {"move_speed_mult": 1.5, "damage_mult": 1.5}
	var aura_intent: Dictionary = service.tick_intent({
		"delta": 0.1,
		"ring_length": 24.0,
		"star_soul": aura,
		"units": units,
		"timers": {"attack_cooldown": 9.0},
	})
	_require(_has_aura_event(Array(aura_intent.get("events", [])), 1, "ally_buff"), "Ally in range should receive aura buff event.")
	_require(not _has_aura_event(Array(aura_intent.get("events", [])), 2, "ally_buff"), "Enemy should not receive ally buff event.")

	var cart := star_soul.duplicate(true)
	Dictionary(cart["stats"])["star_soul_behavior"] = "attack_path_blockers"
	Dictionary(cart["stats"])["range"] = 0.42
	Dictionary(cart["stats"])["normal_damage"] = 7
	Dictionary(cart["stats"])["ally_buffs"] = {"nearby_ally_speed_mult": 1.5}
	var cart_units := [
		{"id": 1, "owner": 1, "ring": 0.2, "lane": 0.0, "radius": 0.2, "live": true},
		{"id": 2, "owner": 2, "ring": 0.3, "lane": 0.0, "radius": 0.2, "live": true},
		{"id": 3, "owner": 2, "ring": 2.4, "lane": 0.0, "radius": 0.2, "live": true},
	]
	var cart_intent: Dictionary = service.tick_intent({
		"delta": 0.6,
		"ring_length": 24.0,
		"star_soul": cart,
		"units": cart_units,
		"timers": {"contact_timers": {}},
	})
	var cart_events: Array = Array(cart_intent.get("events", []))
	_require(_has_damage_event(cart_events, 2, "contact"), "Cart should damage an enemy blocking its path.")
	_require(_has_aura_event(cart_events, 1, "ally_buff"), "Cart should accelerate nearby allies.")

	var chaser := star_soul.duplicate(true)
	Dictionary(chaser["stats"])["range"] = 0.5
	Dictionary(chaser["stats"])["normal_damage"] = 8
	Dictionary(chaser["stats"])["damage_type"] = "blunt"
	var chaser_units := [
		{"id": 1, "owner": 1, "ring": 0.24, "lane": 0.0, "radius": 0.2, "live": true},
		{"id": 2, "owner": 2, "ring": 0.34, "lane": 0.0, "radius": 0.2, "live": true},
	]
	Dictionary(chaser["stats"])["star_soul_behavior"] = "retarget_after_attack"
	var giant_intent: Dictionary = service.tick_intent({
		"delta": 0.55,
		"ring_length": 24.0,
		"star_soul": chaser,
		"units": chaser_units,
		"timers": {"attack_cooldown": 0.0},
	})
	_require(_has_damage_event(Array(giant_intent.get("events", [])), 1, "melee"), "Wandering giant should hit the nearest unit from either side.")

	Dictionary(chaser["stats"])["star_soul_behavior"] = "attack_owner_units"
	var traitor_intent: Dictionary = service.tick_intent({
		"delta": 0.55,
		"ring_length": 24.0,
		"star_soul": chaser,
		"units": chaser_units,
		"timers": {"attack_cooldown": 0.0},
	})
	_require(_has_damage_event(Array(traitor_intent.get("events", [])), 1, "melee"), "Traitor/Rebel should hit owner-side units.")
	_require(not _has_damage_event(Array(traitor_intent.get("events", [])), 2, "melee"), "Traitor/Rebel should not prefer enemy units.")

	Dictionary(chaser["stats"])["star_soul_behavior"] = "attack_enemy_units"
	var loyalist_intent: Dictionary = service.tick_intent({
		"delta": 0.55,
		"ring_length": 24.0,
		"star_soul": chaser,
		"units": chaser_units,
		"timers": {"attack_cooldown": 0.0},
	})
	_require(_has_damage_event(Array(loyalist_intent.get("events", [])), 2, "melee"), "Loyalist should hit enemy units.")

	if failed:
		quit(1)
		return
	print("STAR_SOUL_BEHAVIOR_SERVICE_PROBE ok events=", events.size() + area_events.size() + cart_events.size() + Array(giant_intent.get("events", [])).size())
	quit(0)


func _has_damage_event(events: Array, target_id: int, source_kind: String) -> bool:
	for raw_event in events:
		if raw_event is Dictionary:
			var event: Dictionary = raw_event
			if String(event.get("type", "")) == "damage" and int(event.get("target_id", 0)) == target_id and String(event.get("source_kind", "")) == source_kind:
				return true
	return false


func _has_aura_event(events: Array, target_id: int, aura_kind: String) -> bool:
	for raw_event in events:
		if raw_event is Dictionary:
			var event: Dictionary = raw_event
			if String(event.get("type", "")) == "aura" and int(event.get("target_id", 0)) == target_id and String(event.get("aura_kind", "")) == aura_kind:
				return true
	return false


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
