extends RefCounted
class_name BattleHudStateService


func timer_text(match_time_remaining: float) -> String:
	var safe_time := maxf(0.0, match_time_remaining)
	var minutes := int(floorf(safe_time / 60.0))
	var seconds := int(floorf(fmod(safe_time, 60.0)))
	return "%02d:%02d" % [minutes, seconds]


func _display_max_int(value) -> int:
	return maxi(0, int(value))


func _display_health(unit_state: Dictionary) -> int:
	var max_health := _display_max_int(unit_state.get("max_health", 0))
	return clampi(int(unit_state.get("health", 0)), 0, max_health)


func _display_armor_hp(unit_state: Dictionary, hp_key: String, max_key: String) -> float:
	var armor_max := maxf(0.0, float(unit_state.get(max_key, 0.0)))
	return clampf(float(unit_state.get(hp_key, 0.0)), 0.0, armor_max)


func _display_ratio(value) -> float:
	return clampf(float(value), 0.0, 1.0)


func _display_ratio_percent(value) -> int:
	return int(roundf(_display_ratio(value) * 100.0))


func _display_combat_state(unit_state: Dictionary, terms: Dictionary) -> String:
	var state_text := String(unit_state.get("combat_state", "")).strip_edges()
	if state_text == "" or state_text.to_lower() == "normal":
		state_text = String(terms.get("normal", "normal"))
	if float(unit_state.get("blind_strength", 0.0)) > 0.08:
		state_text = String(terms.get("blind", "blind"))
	elif bool(unit_state.get("overheated", false)):
		state_text = String(terms.get("overheat", "overheat"))
	elif float(unit_state.get("stagger_timer", 0.0)) > 0.0:
		state_text = String(terms.get("stagger", "stagger"))
	return state_text


func unit_status_text(unit_state: Dictionary, fallback: String, terms: Dictionary, hp_label: String) -> String:
	if not bool(unit_state.get("live", false)):
		return "%s: %s" % [fallback, String(terms.get("offline", "offline"))]
	var state_text := _display_combat_state(unit_state, terms)
	var armor_text := ""
	var support_armor_hp := maxf(0.0, float(unit_state.get("support_armor_hp", 0.0)))
	if float(unit_state.get("support_armor_timer", 0.0)) > 0.0 and support_armor_hp > 0.0:
		armor_text = " %s%.0f" % [String(terms.get("support_armor", "armor")), support_armor_hp]
	var electronic_armor_text := ""
	var electronic_armor_max := maxf(0.0, float(unit_state.get("electronic_armor_max", 0.0)))
	if electronic_armor_max > 0.0:
		electronic_armor_text = " %s%.0f/%.0f" % [
			String(terms.get("electronic_armor", "shield")),
			_display_armor_hp(unit_state, "electronic_armor_hp", "electronic_armor_max"),
			electronic_armor_max,
		]
	var heat_text := ""
	if bool(unit_state.get("uses_heat", false)):
		heat_text = "  %s %d%%" % [String(terms.get("heat", "heat")), _display_ratio_percent(unit_state.get("heat_ratio", 0.0))]
	return "%s %s %d/%d%s%s%s  %s" % [
		fallback,
		hp_label,
		_display_health(unit_state),
		_display_max_int(unit_state.get("max_health", 0)),
		armor_text,
		electronic_armor_text,
		heat_text,
		state_text,
	]


func role_status_text(role_state: Dictionary, terms: Dictionary, hp_label: String) -> String:
	var role_name := String(role_state.get("role_name", ""))
	if bool(role_state.get("pending", false)):
		return "%s: %s %.1fs" % [role_name, String(terms.get("deploy", "deploy")), float(role_state.get("pending_time", 0.0))]
	return unit_status_text(Dictionary(role_state.get("unit", {})), role_name, terms, hp_label)


func ammo_display_text(ammo_state: Dictionary, terms: Dictionary) -> String:
	if not bool(ammo_state.get("has_ammo", false)):
		return ""
	return "%s B%d/%d C%d/%d L%d/%d" % [
		String(terms.get("ammo", "ammo")),
		int(ammo_state.get("bullet_current", 0)),
		int(ammo_state.get("bullet_capacity", 0)),
		int(ammo_state.get("chemical_current", 0)),
		int(ammo_state.get("chemical_capacity", 0)),
		int(ammo_state.get("laser_current", 0)),
		int(ammo_state.get("laser_capacity", 0)),
	]


func ammo_breakdown(ammo_state: Dictionary) -> Dictionary:
	var result := {}
	var entries: Dictionary = Dictionary(ammo_state.get("entries", {}))
	for raw_kind in Array(ammo_state.get("types", entries.keys())):
		var kind := String(raw_kind)
		var entry: Dictionary = Dictionary(entries.get(kind, {}))
		var current := int(entry.get("current", 0))
		var capacity := int(entry.get("capacity", 0))
		if capacity > 0 or current > 0:
			result[kind] = {"current": current, "capacity": capacity}
	return result


func role_bar_ratios(role_state: Dictionary, heat_enabled: bool = true) -> Dictionary:
	if bool(role_state.get("pending", false)):
		return {"health_ratio": 0.0, "shield_ratio": 0.0, "heat_ratio": 0.0}
	return {
		"health_ratio": clampf(float(role_state.get("health_ratio", 0.0)), 0.0, 1.0),
		"shield_ratio": clampf(float(role_state.get("shield_ratio", 0.0)), 0.0, 1.0),
		"heat_ratio": clampf(float(role_state.get("heat_ratio", 0.0)) if heat_enabled else 0.0, 0.0, 1.0),
	}


func corner_bar_model(player_id: int, max_width: float, ratio: float, min_visible_width: float = 0.0) -> Dictionary:
	var clamped := clampf(ratio, 0.0, 1.0)
	var fill_width := maxf(0.0, max_width) * clamped
	if clamped > 0.001 and min_visible_width > 0.0:
		fill_width = maxf(fill_width, min_visible_width)
	var base_x := 34.0 if player_id == 1 else 886.0
	return {
		"x": base_x if player_id == 1 else base_x + maxf(0.0, max_width) - fill_width,
		"width": fill_width,
		"ratio": clamped,
		"visible": clamped > 0.001,
	}


func shield_corner_bar_model(player_id: int, max_width: float, ratio: float) -> Dictionary:
	return corner_bar_model(player_id, max_width, ratio, 10.0)


func puppet_segment_bar_model(player_id: int, max_width: float, entries: Array, puppet_role_index: int) -> Array:
	var result: Array = []
	var segment_count := entries.size()
	if segment_count <= 0:
		return result
	var gap := 4.0
	var safe_width := maxf(0.0, max_width)
	var segment_width := maxf(2.0, (safe_width - gap * float(segment_count - 1)) / float(segment_count))
	var base_x := 34.0 if player_id == 1 else 886.0
	var base_y := 72.0 + float(maxi(0, puppet_role_index)) * 23.0 + 15.0
	for i in range(segment_count):
		var entry: Dictionary = Dictionary(entries[i])
		var ratio := clampf(float(entry.get("ratio", 0.0)), 0.0, 1.0)
		var shield_ratio := clampf(float(entry.get("shield_ratio", 0.0)), 0.0, 1.0)
		var x := base_x + float(i) * (segment_width + gap)
		var fill_width := segment_width * ratio
		var shield_width := maxf(segment_width * shield_ratio, minf(7.0, segment_width))
		result.append({
			"index": i,
			"ratio": ratio,
			"shield_ratio": shield_ratio,
			"temporary": bool(entry.get("temporary", false)),
			"back": {
				"x": x,
				"y": base_y,
				"width": segment_width,
				"height": 10.0,
				"visible": true,
			},
			"fill": {
				"x": x if player_id == 1 else x + segment_width - fill_width,
				"y": base_y,
				"width": fill_width,
				"height": 10.0,
				"visible": ratio > 0.001,
			},
			"shield": {
				"x": x if player_id == 1 else x + segment_width - shield_width,
				"y": base_y,
				"width": shield_width,
				"height": 5.0,
				"visible": shield_ratio > 0.001,
			},
		})
	return result


func instrument_gauge_model(unit_state: Dictionary) -> Dictionary:
	if not bool(unit_state.get("live", false)):
		return {"visible": false, "speed": 0.0, "speed_max": 1.0, "ammo": {}}
	var speed := maxf(0.0, float(unit_state.get("speed", 0.0)))
	var boost_speed := maxf(0.0, float(unit_state.get("boost_speed", 0.0)))
	var body_speed := maxf(0.0, float(unit_state.get("move_speed", 0.0)))
	var configured_limit := maxf(0.0, float(unit_state.get("speedometer_max_speed", 0.0)))
	var fallback_limit := maxf(1.0, maxf(boost_speed * 2.0, body_speed * 3.0) * 1.5)
	return {
		"visible": true,
		"speed": speed,
		"speed_max": maxf(speed, configured_limit if configured_limit > 0.001 else fallback_limit),
		"ammo": Dictionary(unit_state.get("ammo", {})).duplicate(true),
	}


func heavy_hud_bar_state(snapshot: Dictionary) -> Dictionary:
	var state := {"players": {}}
	var players: Dictionary = Dictionary(snapshot.get("players", {}))
	var role_order: Array = Array(snapshot.get("role_order", []))
	var heat_enabled := bool(snapshot.get("heat_hud_enabled", true))
	var max_width := float(snapshot.get("max_width", 330.0))
	var puppet_role_index := maxi(0, role_order.find("puppet"))
	for raw_player_id in players.keys():
		var player_id := int(raw_player_id)
		var player: Dictionary = Dictionary(players[raw_player_id])
		var roles: Dictionary = Dictionary(player.get("roles", {}))
		var role_models := {}
		for raw_role_key in role_order:
			var role_key := String(raw_role_key)
			var role_state: Dictionary = Dictionary(roles.get(role_key, {}))
			var ratios := role_bar_ratios(role_state, heat_enabled)
			if role_key == "puppet":
				ratios["puppet_segments"] = puppet_segment_bar_model(player_id, max_width, Array(role_state.get("puppet_entries", [])), puppet_role_index)
			role_models[role_key] = ratios
		state["players"][player_id] = {"roles": role_models}
	return state


func role_bar_text(role_state: Dictionary, terms: Dictionary) -> String:
	if bool(role_state.get("pending", false)):
		return "%s %.1fs" % [String(terms.get("deploy", "deploy")), float(role_state.get("pending_time", 0.0))]
	var role_key := String(role_state.get("role_key", ""))
	if role_key == "puppet":
		var entries: Array = Array(role_state.get("puppet_entries", []))
		if entries.is_empty():
			return String(terms.get("offline", "offline"))
		var pieces := PackedStringArray()
		for raw_entry in entries:
			var entry: Dictionary = Dictionary(raw_entry)
			var ratio := _display_ratio(entry.get("ratio", 0.0))
			var suffix := "*" if bool(entry.get("temporary", false)) else ""
			pieces.append("--" if ratio <= 0.001 else "%d%s" % [int(roundf(ratio * 100.0)), suffix])
		return "x%d %s%%" % [entries.size(), "/".join(pieces)]
	var unit_state: Dictionary = Dictionary(role_state.get("unit", {}))
	if not bool(unit_state.get("live", false)):
		return String(terms.get("offline", "offline"))
	var switch_tag := " %s" % String(terms.get("shift", "shift")) if bool(unit_state.get("has_role_switch", false)) else ""
	var electronic_armor_tag := ""
	if maxf(0.0, float(unit_state.get("electronic_armor_max", 0.0))) > 0.0:
		electronic_armor_tag = " %s%.0f" % [String(terms.get("electronic_armor", "shield")), _display_armor_hp(unit_state, "electronic_armor_hp", "electronic_armor_max")]
	if role_key == "hero" and bool(unit_state.get("uses_heat", false)):
		return "%d/%d%s  %s %.0f%%%s" % [
			_display_health(unit_state),
			_display_max_int(unit_state.get("max_health", 0)),
			electronic_armor_tag,
			String(terms.get("heat", "heat")),
			float(_display_ratio_percent(unit_state.get("heat_ratio", 0.0))),
			switch_tag,
		]
	return "%d/%d%s%s" % [_display_health(unit_state), _display_max_int(unit_state.get("max_health", 0)), electronic_armor_tag, switch_tag]


func sortie_entry_runtime_discount_label(entry: Dictionary) -> String:
	var label := "%s#%d" % [String(entry.get("role_name", entry.get("role_key", ""))), int(entry.get("unit_index", 0)) + 1]
	var base_cost := int(entry.get("base_deploy_cost", 0))
	var live_cost := int(entry.get("live_deploy_cost", base_cost))
	label += " $%d" % live_cost
	if live_cost < base_cost:
		label += "<%d" % base_cost
	return label


func sortie_discount_status(entries: Array, max_items: int = 3) -> String:
	var pieces: Array = []
	var limit := mini(max_items, entries.size())
	for i in range(limit):
		var entry: Dictionary = Dictionary(entries[i])
		pieces.append("%d:%s" % [i + 1, sortie_entry_runtime_discount_label(entry)])
	return " ".join(pieces)


func heavy_hud_text_state(snapshot: Dictionary) -> Dictionary:
	var terms: Dictionary = Dictionary(snapshot.get("terms", {}))
	var hp_label := String(snapshot.get("hp_label", "HP"))
	var win_points := int(snapshot.get("win_points", 0))
	var state := {
		"mode": {"text": String(snapshot.get("mode_title", ""))},
		"timer": {"text": timer_text(float(snapshot.get("match_time_remaining", 0.0)))},
	}
	var players: Dictionary = Dictionary(snapshot.get("players", {}))
	var role_order: Array = Array(snapshot.get("role_order", []))
	for raw_player_id in players.keys():
		var player_id := int(raw_player_id)
		var player: Dictionary = Dictionary(players[raw_player_id])
		state["p%d_resource" % player_id] = {"text": "P%d %s %d" % [player_id, String(terms.get("resource", "resource")), int(player.get("resource", 0))]}
		state["p%d_victory" % player_id] = {"text": "%s %d/%d" % [String(terms.get("victory_points", "VP")), int(player.get("victory_points", 0)), win_points]}
		state["p%d_portal" % player_id] = {"text": "%s %s  %s" % [String(terms.get("portal", "portal")), String(player.get("portal_name", "")), sortie_discount_status(Array(player.get("sortie_discount_entries", [])), int(snapshot.get("sortie_discount_max_items", 3)))]}
		var roles: Dictionary = Dictionary(player.get("roles", {}))
		for i in range(role_order.size()):
			var role_key := String(role_order[i])
			var role_state: Dictionary = Dictionary(roles.get(role_key, {}))
			state["p%d_%s_bar" % [player_id, role_key]] = {"text": role_bar_text(role_state, terms)}
			state["p%d_status_%d" % [player_id, i]] = {"text": role_status_text(role_state, terms, hp_label)}
		var ammo_display := ammo_display_text(Dictionary(player.get("hero_ammo", {})), terms)
		state["p%d_hero_ammo" % player_id] = {"text": ammo_display, "visible": ammo_display != ""}
	return state
