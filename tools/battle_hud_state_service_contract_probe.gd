extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleHudStateService := preload("res://scripts/services/battle_hud_state_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/battle_hud_state_service.gd")
	if source.is_empty():
		_fail("Unable to read BattleHudStateService.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "Control.new", "Label", "ColorRect", "active_units", "all_units", "_compute_unit_stats", "queue_free", "_spawn_", "take_hit"]:
		if source.contains(forbidden):
			_fail("BattleHudStateService contains forbidden token: %s" % forbidden)
			return
	var service := BattleHudStateService.new()
	if service.timer_text(125.4) != "02:05":
		_fail("timer_text mismatch: %s" % service.timer_text(125.4))
		return
	var terms := {
		"offline": "OFF",
		"blind": "BLIND",
		"overheat": "HOT",
		"stagger": "STAG",
		"support_armor": "ARM",
		"electronic_armor": "EA",
		"heat": "HEAT",
		"deploy": "DEP",
		"ammo": "AMMO",
		"resource": "RES",
		"victory_points": "VP",
		"portal": "PORT",
		"shift": "SHIFT",
		"normal": "OK",
	}
	var unit_state := {
		"live": true,
		"health": 7,
		"max_health": 10,
		"blind_strength": 0.0,
		"overheated": false,
		"stagger_timer": 0.0,
		"combat_state": "ACTIVE",
		"support_armor_timer": 0.0,
		"support_armor_hp": 0.0,
		"electronic_armor_hp": 2.0,
		"electronic_armor_max": 4.0,
		"uses_heat": true,
		"heat_ratio": 0.34,
		"has_role_switch": true,
	}
	var status := service.unit_status_text(unit_state, "HERO", terms, "HP")
	if not status.contains("HERO HP 7/10") or not status.contains("HEAT 34%") or not status.contains("ACTIVE"):
		_fail("unit_status_text mismatch: %s" % status)
		return
	var clamped_status := service.unit_status_text({
		"live": true,
		"health": -5,
		"max_health": 10,
		"combat_state": "",
		"electronic_armor_hp": -2.0,
		"electronic_armor_max": 4.0,
		"uses_heat": true,
		"heat_ratio": 1.45,
	}, "HERO", terms, "HP")
	if not clamped_status.contains("HERO HP 0/10") or not clamped_status.contains("EA0/4") or not clamped_status.contains("HEAT 100%") or not clamped_status.ends_with("OK"):
		_fail("unit_status_text should clamp display values and use normal fallback: %s" % clamped_status)
		return
	var role_state := {"role_key": "hero", "role_name": "HERO", "pending": false, "unit": unit_state}
	var bar_text := service.role_bar_text(role_state, terms)
	if not bar_text.contains("7/10") or not bar_text.contains("EA2") or not bar_text.contains("SHIFT"):
		_fail("role_bar_text mismatch: %s" % bar_text)
		return
	var clamped_bar_text := service.role_bar_text({
		"role_key": "hero",
		"unit": {
			"live": true,
			"health": 14,
			"max_health": 10,
			"uses_heat": true,
			"heat_ratio": 1.5,
			"electronic_armor_hp": -1.0,
			"electronic_armor_max": 2.0,
		},
	}, terms)
	if clamped_bar_text != "10/10 EA0  HEAT 100%":
		_fail("role_bar_text should clamp hero HUD values: %s" % clamped_bar_text)
		return
	var puppet_text := service.role_bar_text({
		"role_key": "puppet",
		"pending": false,
		"puppet_entries": [{"ratio": 0.5, "temporary": false}, {"ratio": 0.0, "temporary": true}],
	}, terms)
	if puppet_text != "x2 50/--%":
		_fail("puppet role bar mismatch: %s" % puppet_text)
		return
	var clamped_puppet_text := service.role_bar_text({
		"role_key": "puppet",
		"pending": false,
		"puppet_entries": [{"ratio": 1.5, "temporary": false}, {"ratio": -0.2, "temporary": true}],
	}, terms)
	if clamped_puppet_text != "x2 100/--%":
		_fail("puppet role bar should clamp segment ratios: %s" % clamped_puppet_text)
		return
	var ammo_text := service.ammo_display_text({
		"has_ammo": true,
		"bullet_current": 1,
		"bullet_capacity": 4,
		"chemical_current": 2,
		"chemical_capacity": 5,
		"laser_current": 3,
		"laser_capacity": 6,
	}, terms)
	if ammo_text != "AMMO B1/4 C2/5 L3/6":
		_fail("ammo text mismatch: %s" % ammo_text)
		return
	var ammo_breakdown := service.ammo_breakdown({
		"types": ["bullet", "chemical", "laser"],
		"entries": {
			"bullet": {"current": 0, "capacity": 0},
			"chemical": {"current": 2, "capacity": 5},
			"laser": {"current": 1, "capacity": 0},
		},
	})
	if ammo_breakdown.has("bullet") or int(Dictionary(ammo_breakdown.get("chemical", {})).get("capacity", 0)) != 5 or int(Dictionary(ammo_breakdown.get("laser", {})).get("current", 0)) != 1:
		_fail("ammo_breakdown mismatch: %s" % str(ammo_breakdown))
		return
	var ratios := service.role_bar_ratios({"health_ratio": 0.75, "shield_ratio": 0.25, "heat_ratio": 0.5}, false)
	if absf(float(ratios.get("health_ratio", 0.0)) - 0.75) > 0.001 or absf(float(ratios.get("shield_ratio", 0.0)) - 0.25) > 0.001 or float(ratios.get("heat_ratio", 1.0)) != 0.0:
		_fail("role_bar_ratios mismatch: %s" % str(ratios))
		return
	var p1_bar := service.corner_bar_model(1, 330.0, 0.5)
	var p2_bar := service.corner_bar_model(2, 330.0, 0.25)
	if absf(float(p1_bar.get("x", 0.0)) - 34.0) > 0.001 or absf(float(p1_bar.get("width", 0.0)) - 165.0) > 0.001:
		_fail("P1 corner bar mismatch: %s" % str(p1_bar))
		return
	if absf(float(p2_bar.get("x", 0.0)) - (886.0 + 330.0 - 82.5)) > 0.001 or absf(float(p2_bar.get("width", 0.0)) - 82.5) > 0.001:
		_fail("P2 corner bar mismatch: %s" % str(p2_bar))
		return
	var shield_bar := service.shield_corner_bar_model(1, 330.0, 0.01)
	if absf(float(shield_bar.get("width", 0.0)) - 10.0) > 0.001:
		_fail("shield corner bar minimum width mismatch: %s" % str(shield_bar))
		return
	var puppet_segments := service.puppet_segment_bar_model(2, 330.0, [{"ratio": 0.5, "shield_ratio": 0.25, "temporary": false}, {"ratio": 0.0, "shield_ratio": 0.0, "temporary": true}], 1)
	if puppet_segments.size() != 2:
		_fail("puppet segment count mismatch: %s" % str(puppet_segments))
		return
	var first_segment: Dictionary = Dictionary(puppet_segments[0])
	var first_fill: Dictionary = Dictionary(first_segment.get("fill", {}))
	var first_back: Dictionary = Dictionary(first_segment.get("back", {}))
	if not bool(first_fill.get("visible", false)) or float(first_fill.get("x", 0.0)) <= float(first_back.get("x", 0.0)):
		_fail("P2 puppet segment mirrored fill mismatch: %s" % str(first_segment))
		return
	var gauge_model := service.instrument_gauge_model({
		"live": true,
		"speed": 6.0,
		"boost_speed": 2.0,
		"move_speed": 1.0,
		"speedometer_max_speed": 0.0,
		"ammo": {"chemical": {"current": 2, "capacity": 5}},
	})
	if not bool(gauge_model.get("visible", false)) or absf(float(gauge_model.get("speed_max", 0.0)) - 6.0) > 0.001 or not Dictionary(gauge_model.get("ammo", {})).has("chemical"):
		_fail("instrument gauge model mismatch: %s" % str(gauge_model))
		return
	var hidden_gauge := service.instrument_gauge_model({"live": false})
	if bool(hidden_gauge.get("visible", true)):
		_fail("dead unit gauge should be hidden: %s" % str(hidden_gauge))
		return
	var discount_label := service.sortie_entry_runtime_discount_label({"role_name": "HERO", "unit_index": 1, "base_deploy_cost": 100, "live_deploy_cost": 80})
	if discount_label != "HERO#2 $80<100":
		_fail("discount label mismatch: %s" % discount_label)
		return
	var hud_model := service.heavy_hud_text_state({
		"mode_title": "TRAINING",
		"match_time_remaining": 61.0,
		"win_points": 2,
		"role_order": ["hero", "puppet", "barrier"],
		"terms": terms,
		"hp_label": "HP",
		"players": {
			1: {
				"resource": 9,
				"victory_points": 1,
				"portal_name": "Gate",
				"sortie_discount_entries": [{"role_name": "HERO", "unit_index": 0, "base_deploy_cost": 50, "live_deploy_cost": 50}],
				"roles": {"hero": role_state, "puppet": {"role_key": "puppet", "role_name": "PUP", "pending": true, "pending_time": 1.2, "unit": {}}, "barrier": {"role_key": "barrier", "role_name": "BAR", "pending": false, "unit": {"live": false}}},
				"hero_ammo": {"has_ammo": false},
			},
		},
	})
	if String(Dictionary(hud_model.get("timer", {})).get("text", "")) != "01:01":
		_fail("HUD model timer mismatch: %s" % str(hud_model))
		return
	if String(Dictionary(hud_model.get("p1_portal", {})).get("text", "")) != "PORT Gate  1:HERO#1 $50":
		_fail("HUD portal model mismatch: %s" % str(hud_model.get("p1_portal", {})))
		return
	if bool(Dictionary(hud_model.get("p1_hero_ammo", {})).get("visible", true)):
		_fail("HUD ammo visibility should be false when empty.")
		return
	var bar_model := service.heavy_hud_bar_state({
		"role_order": ["hero", "puppet", "barrier"],
		"heat_hud_enabled": true,
		"max_width": 330.0,
		"players": {
			1: {
				"roles": {
					"hero": {"health_ratio": 0.8, "shield_ratio": 0.2, "heat_ratio": 0.1},
					"puppet": {"puppet_entries": [{"ratio": 0.4, "shield_ratio": 0.0, "temporary": false}]},
					"barrier": {},
				},
			},
		},
	})
	var player_bars: Dictionary = Dictionary(Dictionary(bar_model.get("players", {})).get(1, {}))
	var role_bars: Dictionary = Dictionary(player_bars.get("roles", {}))
	if absf(float(Dictionary(role_bars.get("hero", {})).get("health_ratio", 0.0)) - 0.8) > 0.001:
		_fail("HUD bar hero model mismatch: %s" % str(bar_model))
		return
	if Array(Dictionary(role_bars.get("puppet", {})).get("puppet_segments", [])).is_empty():
		_fail("HUD bar puppet segments missing: %s" % str(bar_model))
		return
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"scripts/services/battle_hud_state_service.gd",
		"BattleHudStateService.new",
		"battle_hud_state_service.heavy_hud_text_state",
		"battle_hud_state_service.heavy_hud_bar_state",
		"battle_hud_state_service.corner_bar_model",
		"battle_hud_state_service.shield_corner_bar_model",
		"battle_hud_state_service.puppet_segment_bar_model",
		"battle_hud_state_service.instrument_gauge_model",
		"battle_hud_state_service.ammo_breakdown",
		"battle_hud_state_service.role_status_text",
		"battle_hud_state_service.role_bar_text",
		"battle_hud_state_service.ammo_display_text",
		"_battle_hud_text_snapshot",
		"_battle_hud_bar_snapshot",
		"_battle_instrument_gauge_model",
		"_battle_hud_sortie_discount_entry",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing BattleHudStateService boundary token: %s" % token)
			return
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var snapshot := main._battle_hud_text_snapshot()
	if not snapshot.has("players") or not Dictionary(snapshot["players"]).has(1):
		_fail("main HUD snapshot missing players: %s" % str(snapshot))
		return
	var bar_snapshot := main._battle_hud_bar_snapshot()
	if not bool(bar_snapshot.get("heat_hud_enabled", false)) or float(bar_snapshot.get("max_width", 0.0)) <= 0.0:
		_fail("main HUD bar snapshot missing model fields: %s" % str(bar_snapshot))
		return
	print("BATTLE_HUD_STATE_SERVICE_CONTRACT_PROBE ok")
	quit(0)
