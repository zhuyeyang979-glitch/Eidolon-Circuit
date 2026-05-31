extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const FighterHeatModel := preload("res://scripts/services/fighter_heat_model.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _fighter(stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "HEAT_MODEL", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/fighter_heat_model.gd")
	if source.is_empty():
		_fail("Unable to read FighterHeatModel.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "Control.new", "Label", "ColorRect", "active_units", "all_units", "queue_free", "_spawn_", "take_hit", "velocity"]:
		if source.contains(forbidden):
			_fail("FighterHeatModel contains forbidden token: %s" % forbidden)
			return
	var model := FighterHeatModel.new()
	var tags := model.canonical_heat_tags_for_reason("heat_event:chemical heat:projectile laser gun")
	for tag in ["chemical", "projectile", "laser"]:
		if not tags.has(tag):
			_fail("canonical_heat_tags_for_reason missing %s in %s" % [tag, str(tags)])
			return
	var relieved := model.heat_amount_after_cooling_relief_for_tags(50.0, ["projectile", "laser"], {"projectile_heat_relief": 0.1, "laser_heat_relief": 0.25})
	if absf(relieved - 37.5) > 0.001:
		_fail("Relief should use strongest matching heat tag, got %.3f" % relieved)
		return
	var event_intent := model.add_heat_event_intent({
		"role": "hero",
		"stats": {"heat_capacity": 100.0, "boost_heat_relief": 0.2},
		"amount": 50.0,
		"tags": ["boost"],
		"source": "boost",
		"heat": 20.0,
	})
	if not bool(event_intent.get("allowed", false)) or absf(float(event_intent.get("heat", 0.0)) - 60.0) > 0.001:
		_fail("add_heat_event_intent mismatch: %s" % str(event_intent))
		return
	var manual := model.manual_cool_intent({
		"active": true,
		"role": "hero",
		"stats": {"heat_capacity": 100.0, "manual_cooling": 20.0, "overheat_clear_ratio": 0.48},
		"delta": 1.0,
		"heat": 80.0,
		"overheated": false,
		"cooling_lock_timer": 0.0,
	})
	if not bool(manual.get("allowed", false)) or absf(float(manual.get("heat", 0.0)) - 70.0) > 0.001 or float(manual.get("cooling_lock_timer", 0.0)) < 0.4:
		_fail("manual_cool_intent mismatch: %s" % str(manual))
		return
	var tick := model.cooling_tick_intent({
		"role": "hero",
		"stats": {"heat_capacity": 100.0, "cooling": 10.0},
		"delta": 1.0,
		"heat": 80.0,
		"overheated": false,
		"manual_cooling": true,
		"moved_this_frame": false,
		"action_cooldown": 0.0,
		"current_state": "normal",
		"straight_inertial_cooling": false,
	})
	if absf(float(tick.get("heat", 0.0)) - 64.0) > 0.001:
		_fail("manual cooling tick multiplier mismatch: %s" % str(tick))
		return
	var shutdown := model.overheat_shutdown_intent({
		"role": "hero",
		"stats": {"heat_capacity": 100.0, "overheat_shutdown_seconds": 0.3, "overheat_shutdown_mult": 0.7},
		"forced_cooling_timer": 0.0,
		"cooling_lock_timer": 0.0,
		"action_cooldown": 0.0,
		"smoke_timer": 0.0,
	})
	if not bool(shutdown.get("allowed", false)) or absf(float(shutdown.get("forced_cooling_timer", 0.0)) - 0.21) > 0.001 or not bool(shutdown.get("manual_cooling", false)):
		_fail("overheat_shutdown_intent mismatch: %s" % str(shutdown))
		return
	var fighter = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "projectile_heat_relief": 0.1, "laser_heat_relief": 0.25})
	fighter.add_heat(40.0, "projectile laser gun")
	if absf(float(fighter.heat) - 30.0) > 0.001:
		_fail("Fighter wrapper should apply model relief, got %.3f" % float(fighter.heat))
		return
	var fighter_source := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	for token in [
		"scripts/services/fighter_heat_model.gd",
		"FighterHeatModel.new",
		"func _heat_model()",
		"_heat_model().cooling_tick_intent",
		"_heat_model().manual_cool_intent",
		"_heat_model().overheat_shutdown_intent",
		"_heat_model().add_heat_event_intent",
		"_heat_model().canonical_heat_tags_for_reason",
		"_heat_model().heat_amount_after_cooling_relief_for_tags",
	]:
		if not fighter_source.contains(token):
			_fail("fighter.gd missing FighterHeatModel boundary token: %s" % token)
			return
	print("FIGHTER_HEAT_MODEL_CONTRACT_PROBE ok relieved=%.1f wrapper=%.1f" % [relieved, float(fighter.heat)])
	quit(0)
