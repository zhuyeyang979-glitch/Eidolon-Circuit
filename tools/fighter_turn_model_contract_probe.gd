extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const FighterTurnModel := preload("res://scripts/services/fighter_turn_model.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _fighter(stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter.setup_unit({"unit_name": "TURN_MODEL", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	fighter.set_facing_immediate(1)
	return fighter


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/fighter_turn_model.gd")
	if source.is_empty():
		_fail("Unable to read FighterTurnModel.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "Control.new", "Label", "ColorRect", "active_units", "all_units", "queue_free", "_spawn_", "take_hit", "add_heat_event"]:
		if source.contains(forbidden):
			_fail("FighterTurnModel contains forbidden token: %s" % forbidden)
			return
	var model := FighterTurnModel.new()
	if absf(model.angle_delta(PI * 1.75, 0.1) - 0.885398) > 0.01:
		_fail("angle_delta should use shortest arc.")
		return
	var face := model.request_facing_intent({"active": true, "direction_sign": -1})
	if not bool(face.get("allowed", false)) or absf(float(face.get("target_facing_angle", 0.0)) - PI) > 0.001 or float(face.get("turn_direction_bias", 0.0)) >= 0.0:
		_fail("request_facing_intent should target left facing: %s" % str(face))
		return
	var turn := model.request_turn_intent({
		"active": true,
		"direction_sign": 1,
		"delta": 0.1,
		"stats": {"turn_speed": 2.0},
		"target_facing_angle": 0.0,
		"turn_input_timer": 0.0,
	})
	if not bool(turn.get("allowed", false)) or absf(float(turn.get("turn_input_timer", 0.0)) - 0.18) > 0.001 or absf(float(turn.get("target_facing_angle", 0.0)) - 0.2) > 0.001:
		_fail("request_turn_intent mismatch: %s" % str(turn))
		return
	var no_rate := model.request_turn_intent({
		"active": true,
		"direction_sign": 1,
		"delta": 0.1,
		"stats": {},
		"target_facing_angle": 0.4,
		"turn_input_timer": 0.0,
	})
	if not bool(no_rate.get("allowed", false)) or absf(float(no_rate.get("target_facing_angle", 0.0)) - 0.4) > 0.001:
		_fail("request_turn_intent should still mark input without command rate: %s" % str(no_rate))
		return
	var tick := model.tick_turn_dynamics_intent({
		"stats": {"turn_speed": 5.0, "turn_acceleration": 12.0, "turn_damping": 0.0},
		"role": "hero",
		"delta": 0.1,
		"turn_input_timer": 0.18,
		"facing_angle": 0.0,
		"target_facing_angle": 0.5,
		"angular_velocity": 0.0,
		"turn_direction_bias": 1.0,
		"current_state": "normal",
	})
	if not bool(tick.get("turn_input_active", false)) or float(tick.get("angular_velocity", 0.0)) <= 0.001 or float(tick.get("facing_angle", 0.0)) <= 0.001:
		_fail("tick_turn_dynamics_intent should accelerate active turn: %s" % str(tick))
		return
	var brake := model.tick_turn_dynamics_intent({
		"stats": {"turn_speed": 5.0, "turn_acceleration": 12.0, "turn_damping": 0.0, "brake_power": 10.0, "boost_duration": 0.2},
		"role": "hero",
		"delta": 0.1,
		"turn_input_timer": 0.0,
		"facing_angle": 0.2,
		"target_facing_angle": 0.5,
		"angular_velocity": 2.0,
		"current_state": "normal",
	})
	if bool(brake.get("turn_input_active", true)) or absf(float(brake.get("angular_velocity", 0.0))) >= 2.0 or absf(float(brake.get("target_facing_angle", 0.0)) - float(brake.get("facing_angle", 0.0))) > 0.001:
		_fail("tick_turn_dynamics_intent should auto-brake inactive turn: %s" % str(brake))
		return
	var fighter = _fighter({"turn_speed": 5.0, "turn_acceleration": 12.0, "turn_damping": 0.0, "brake_power": 10.0, "boost_duration": 0.2})
	fighter.request_turn(1, 0.1)
	fighter.tick(0.1, 24.0)
	if float(fighter.angular_velocity) <= 0.001 or float(fighter.facing_angle) <= 0.001:
		_fail("Fighter wrapper should apply turn model, angle=%.4f angular=%.4f" % [float(fighter.facing_angle), float(fighter.angular_velocity)])
		return
	var fighter_source := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	for token in [
		"scripts/services/fighter_turn_model.gd",
		"FighterTurnModel.new",
		"func _turn_model()",
		"_turn_model().request_facing_intent",
		"_turn_model().request_turn_intent",
		"_turn_model().set_turn_input_active_intent",
		"_turn_model().tick_turn_dynamics_intent",
		"_turn_model().turn_brake_acceleration",
	]:
		if not fighter_source.contains(token):
			_fail("fighter.gd missing FighterTurnModel boundary token: %s" % token)
			return
	print("FIGHTER_TURN_MODEL_CONTRACT_PROBE ok angle=%.3f angular=%.3f" % [float(fighter.facing_angle), float(fighter.angular_velocity)])
	quit(0)
