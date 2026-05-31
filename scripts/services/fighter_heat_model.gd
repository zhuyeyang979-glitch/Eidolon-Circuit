extends RefCounted
class_name FighterHeatModel

const HEAT_RATE_MULT := 0.5
const HEAT_TAG_PREFIX := "heat:"
const HEAT_TAG_EVENT_PREFIX := "heat_event:"


func uses_heat_resource(role: String) -> bool:
	return role == "hero"


func heat_capacity(stats: Dictionary) -> float:
	return maxf(1.0, float(stats.get("heat_capacity", 100.0)))


func overheat_clear_ratio(stats: Dictionary) -> float:
	return clampf(float(stats.get("overheat_clear_ratio", 0.42)), 0.3, 0.62)


func runtime_cooling_rate(stats: Dictionary) -> float:
	var rate := maxf(0.0, float(stats.get("cooling_rate", stats.get("cooling", 12.0))))
	rate = maxf(rate, float(stats.get("cooling", 0.0)))
	rate = maxf(rate, float(stats.get("thermal_dissipation_rate", 0.0)))
	rate = maxf(rate, float(stats.get("heat_dissipation", 0.0)))
	rate = maxf(rate, float(stats.get("runtime_cooling_rate", 0.0)))
	return rate


func cooling_tick_intent(context: Dictionary) -> Dictionary:
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	var role := String(context.get("role", ""))
	if not uses_heat_resource(role):
		return {"uses_heat": false, "heat": 0.0, "overheated": false, "manual_cooling": false}
	var capacity := heat_capacity(stats)
	var cooling := runtime_cooling_rate(stats)
	var delta := maxf(0.0, float(context.get("delta", 0.0)))
	var current_heat := clampf(float(context.get("heat", 0.0)), 0.0, capacity)
	var current_overheated := bool(context.get("overheated", false))
	var cooling_mult := 0.35 if bool(context.get("moved_this_frame", false)) or float(context.get("action_cooldown", 0.0)) > 0.0 or String(context.get("current_state", "normal")) != "normal" else 1.15
	if bool(context.get("straight_inertial_cooling", false)):
		cooling_mult = 3.2
	if bool(context.get("manual_cooling", false)):
		cooling_mult = 3.2
	var next_heat := clampf(current_heat - cooling * cooling_mult * delta * HEAT_RATE_MULT, 0.0, capacity)
	var next_overheated := current_overheated
	var trigger_shutdown := false
	if next_heat >= capacity:
		trigger_shutdown = true
	elif next_overheated and next_heat <= capacity * overheat_clear_ratio(stats):
		next_overheated = false
	return {
		"uses_heat": true,
		"heat": next_heat,
		"overheated": next_overheated,
		"cooling_mult": cooling_mult,
		"trigger_overheat_shutdown": trigger_shutdown,
	}


func manual_cool_intent(context: Dictionary) -> Dictionary:
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	var role := String(context.get("role", ""))
	if not bool(context.get("active", false)) or role != "hero":
		return {"allowed": false}
	if float(context.get("melee_stagger_timer", 0.0)) > 0.0:
		return {"allowed": false}
	var delta := maxf(0.0, float(context.get("delta", 0.0)))
	var capacity := heat_capacity(stats)
	var next_heat := clampf(float(context.get("heat", 0.0)) - float(stats.get("manual_cooling", 48.0)) * delta * HEAT_RATE_MULT, 0.0, capacity)
	var next_overheated := bool(context.get("overheated", false))
	if next_overheated and next_heat <= capacity * overheat_clear_ratio(stats):
		next_overheated = false
	return {
		"allowed": true,
		"heat": next_heat,
		"overheated": next_overheated,
		"manual_cooling": true,
		"smoke_timer": 0.18,
		"cooling_lock_timer": maxf(float(context.get("cooling_lock_timer", 0.0)), 0.4),
	}


func overheat_shutdown_intent(context: Dictionary) -> Dictionary:
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	var role := String(context.get("role", ""))
	if not uses_heat_resource(role):
		return {"allowed": false}
	var capacity := heat_capacity(stats)
	var shutdown_mult := clampf(float(stats.get("overheat_shutdown_mult", 1.0)), 0.35, 1.0)
	var forced_timer := maxf(float(context.get("forced_cooling_timer", 0.0)), float(stats.get("overheat_shutdown_seconds", 0.3)) * shutdown_mult)
	return {
		"allowed": true,
		"heat": capacity,
		"overheated": true,
		"forced_cooling_timer": forced_timer,
		"cooling_lock_timer": maxf(float(context.get("cooling_lock_timer", 0.0)), forced_timer),
		"action_cooldown": maxf(float(context.get("action_cooldown", 0.0)), forced_timer),
		"current_state": "normal",
		"state_timer": 0.0,
		"manual_cooling": true,
		"smoke_timer": maxf(float(context.get("smoke_timer", 0.0)), forced_timer + 0.12),
		"motion_mult": 0.82,
	}


func add_heat_event_intent(context: Dictionary) -> Dictionary:
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	var role := String(context.get("role", ""))
	var amount := maxf(0.0, float(context.get("amount", 0.0)))
	if not uses_heat_resource(role) or amount <= 0.0:
		return {"allowed": false}
	var capacity := heat_capacity(stats)
	var source := String(context.get("source", ""))
	var canonical_tags := canonical_heat_tags_for_event(Array(context.get("tags", [])), source)
	var relieved_amount := heat_amount_after_cooling_relief_for_tags(amount, canonical_tags, stats)
	var next_heat := clampf(float(context.get("heat", 0.0)) + relieved_amount, 0.0, capacity)
	return {
		"allowed": true,
		"heat": next_heat,
		"trigger_overheat_shutdown": next_heat >= capacity,
		"heat_event": {
			"heat_event_amount": amount,
			"heat_event_relief_amount": amount - relieved_amount,
			"heat_event_tags": canonical_tags.duplicate(),
			"heat_event_source": source,
		},
	}


func heat_amount_after_cooling_relief(amount: float, reason: String, stats: Dictionary) -> float:
	return heat_amount_after_cooling_relief_for_tags(amount, canonical_heat_tags_for_reason(reason), stats)


func heat_amount_after_cooling_relief_for_tags(amount: float, tags: Array, stats: Dictionary) -> float:
	var relief := 0.0
	for tag in tags:
		match String(tag):
			"boost":
				relief = maxf(relief, float(stats.get("boost_heat_relief", 0.0)))
			"repeat":
				relief = maxf(relief, float(stats.get("repeat_heat_relief", 0.0)))
			"projectile":
				relief = maxf(relief, float(stats.get("projectile_heat_relief", 0.0)))
			"laser":
				relief = maxf(relief, float(stats.get("laser_heat_relief", 0.0)))
			"chemical":
				relief = maxf(relief, float(stats.get("chemical_heat_relief", 0.0)))
			"missile":
				relief = maxf(relief, float(stats.get("missile_heat_relief", 0.0)))
	return amount * (1.0 - clampf(relief, 0.0, 0.72))


func canonical_heat_tags_for_event(tags: Array, source: String = "") -> Array:
	var canonical: Array = []
	for raw_tag in tags:
		append_heat_tag(canonical, String(raw_tag))
	if canonical.is_empty() and source.strip_edges() != "":
		for tag in canonical_heat_tags_for_reason(source):
			append_heat_tag(canonical, String(tag))
	return canonical


func canonical_heat_tags_for_reason(reason: String) -> Array:
	var tags: Array = []
	var reason_key := reason.to_lower()
	var explicit_text := reason_key.replace(",", " ").replace(";", " ").replace("|", " ")
	for token in explicit_text.split(" ", false):
		var token_text := String(token).strip_edges()
		if token_text.begins_with(HEAT_TAG_PREFIX):
			append_heat_tag(tags, token_text.substr(HEAT_TAG_PREFIX.length()))
		elif token_text.begins_with(HEAT_TAG_EVENT_PREFIX):
			append_heat_tag(tags, token_text.substr(HEAT_TAG_EVENT_PREFIX.length()))
	if reason_key.contains("boost"):
		append_heat_tag(tags, "boost")
	if reason_key.contains("gauntlet") or reason_key.contains("blade") or reason_key.contains("blunt") or reason_key.contains("combo") or reason_key.contains("module"):
		append_heat_tag(tags, "repeat")
	if reason_key.contains("projectile") or reason_key.contains("gun") or reason_key.contains("ammo"):
		append_heat_tag(tags, "projectile")
	if reason_key.contains("laser"):
		append_heat_tag(tags, "laser")
	if reason_key.contains("chemical"):
		append_heat_tag(tags, "chemical")
	if reason_key.contains("missile") or reason_key.contains("explosive"):
		append_heat_tag(tags, "missile")
	if reason_key.contains("external") or reason_key.contains("field") or reason_key.contains("aura"):
		append_heat_tag(tags, "external")
	return tags


func append_heat_tag(tags: Array, raw_tag: String) -> void:
	var tag := raw_tag.strip_edges().to_lower()
	if tag == "":
		return
	match tag:
		"gauntlet", "blade", "blunt", "combo", "module", "melee":
			tag = "repeat"
		"gun", "ammo", "bullet", "true_bullet", "bullet_hell", "web":
			tag = "projectile"
		"explosive", "grenade":
			tag = "missile"
		"field", "aura":
			tag = "external"
	if not tags.has(tag):
		tags.append(tag)
