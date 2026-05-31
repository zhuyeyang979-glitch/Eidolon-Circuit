extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const FighterMovementModel := preload("res://scripts/services/fighter_movement_model.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _fighter(stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter.setup_unit({"unit_name": "MOVE_MODEL", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	fighter.set_facing_immediate(1)
	return fighter


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/fighter_movement_model.gd")
	if source.is_empty():
		_fail("Unable to read FighterMovementModel.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "Control.new", "Label", "ColorRect", "active_units", "all_units", "queue_free", "_spawn_", "take_hit", "add_heat_event"]:
		if source.contains(forbidden):
			_fail("FighterMovementModel contains forbidden token: %s" % forbidden)
			return
	var model := FighterMovementModel.new()
	if model.speedometer_max_speed({"move_speed": 2.0, "boost_speed": 5.0}) < 14.999:
		_fail("speedometer_max_speed should use move/boost derived limit.")
		return
	if absf(model.brake_delta_velocity({"brake_power": 3.0, "move_momentum": 90.0, "mass": 10.0}) - 3.0) > 0.001:
		_fail("brake_delta_velocity should prefer brake_power.")
		return
	if absf(model.brake_delta_velocity({"move_momentum": 90.0, "mass": 10.0}) - 9.0) > 0.001:
		_fail("brake_delta_velocity should fall back to momentum / mass.")
		return
	var cone_side := model.direction_inside_thruster_cone(Vector2.UP, Vector2.RIGHT, Vector2.UP, 180.0)
	if cone_side.dot(Vector2.UP) < 0.99:
		_fail("180 degree cone should allow side direction, got %s." % str(cone_side))
		return
	var cone_rear := model.direction_inside_thruster_cone(Vector2(-1.0, 1.0), Vector2.RIGHT, Vector2.UP, 120.0)
	if cone_rear.length() <= 0.9 or cone_rear.dot(Vector2.RIGHT) < 0.49:
		_fail("Narrow cone should clamp rear input toward forward edge, got %s." % str(cone_rear))
		return
	var car_boost := model.thruster_boost_direction({"requested": Vector2.LEFT, "forward": Vector2.RIGHT, "stats": {"movement_profile": "car", "boost_angle_degrees": 120.0}})
	if car_boost.length() > 0.001:
		_fail("Car profile should reject rear boost direction.")
		return
	var reverse_context := {
		"input_vector": Vector2.LEFT,
		"brake_reverse_ready_dir": Vector2.LEFT,
		"brake_reverse_ready_timer": 0.3,
		"brake_reverse_requires_repress": false,
	}
	if not model.reverse_drive_allowed(reverse_context):
		_fail("reverse_drive_allowed should accept released/repressed matching direction.")
		return
	reverse_context["brake_reverse_requires_repress"] = true
	if not model.brake_reverse_waiting_for_repress(reverse_context):
		_fail("brake_reverse_waiting_for_repress should report held input gate.")
		return
	var brake_context := {
		"input_vector": Vector2.LEFT,
		"velocity": Vector2.RIGHT * 4.0,
		"stats": {"brake_power": 3.0, "boost_duration": 0.3},
		"brake_reverse_ready_dir": Vector2.ZERO,
		"brake_reverse_ready_timer": 0.0,
	}
	if not model.input_should_velocity_brake(brake_context):
		_fail("Opposed input and velocity should request brake.")
		return
	var brake_intent := model.velocity_brake_intent({
		"velocity": Vector2.RIGHT,
		"stats": {"brake_power": 3.0, "boost_duration": 0.3},
		"delta": 0.0,
		"full_boost": true,
		"reason": "reverse_brake",
		"input_dir": Vector2.LEFT,
	})
	if not bool(brake_intent.get("allowed", false)) or Vector2(brake_intent.get("velocity", Vector2.ONE)).length() > 0.001 or not bool(brake_intent.get("set_reverse_ready", false)):
		_fail("Full brake should stop and request reverse-ready state: %s" % str(brake_intent))
		return
	var command := model.movement_command_intent({
		"input_vector": Vector2.RIGHT,
		"velocity": Vector2.ZERO,
		"forward": Vector2.RIGHT,
		"side": Vector2.UP,
		"stats": {"bidirectional_thrusters": true},
	})
	if String(command.get("mode", "")) != "drive" or Vector2(command.get("drive_dir", Vector2.ZERO)).dot(Vector2.RIGHT) < 0.99:
		_fail("movement_command_intent should drive forward, got %s." % str(command))
		return
	var drive := model.movement_drive_intent({
		"active": true,
		"role": "hero",
		"input_vector": Vector2.RIGHT,
		"velocity": Vector2.ZERO,
		"delta": 0.1,
		"forward": Vector2.RIGHT,
		"side": Vector2.UP,
		"stats": {"move_speed": 5.0, "move_acceleration": 10.0, "cornering": 1.0, "bidirectional_thrusters": true},
		"current_state": "normal",
	})
	if not bool(drive.get("allowed", false)) or absf(Vector2(drive.get("velocity", Vector2.ZERO)).x - 1.0) > 0.001:
		_fail("movement_drive_intent should step velocity by acceleration * delta, got %s." % str(drive))
		return
	var boost := model.boost_intent({
		"active": true,
		"role": "hero",
		"direction": Vector2.RIGHT,
		"velocity": Vector2.ZERO,
		"forward": Vector2.RIGHT,
		"side": Vector2.UP,
		"stats": {"thruster_boost_extra_demand": 20.0, "boost_total_momentum": 80.0, "boost_speed": 3.0, "boost_duration": 0.25, "mass": 10.0, "boost_heat": 7.0, "boost_cooldown": 0.4},
	})
	if not bool(boost.get("allowed", false)) or absf(float(boost.get("delta_v", 0.0)) - 8.0) > 0.001 or absf(float(boost.get("heat", 0.0)) - 7.0) > 0.001:
		_fail("boost_intent should compute delta-v/heat/cooldown, got %s." % str(boost))
		return
	var fighter = _fighter({"mass": 10.0, "move_speed": 5.0, "move_acceleration": 10.0, "cornering": 1.0, "bidirectional_thrusters": true, "thruster_boost_extra_demand": 20.0, "boost_total_momentum": 80.0, "boost_speed": 3.0, "boost_duration": 0.25, "boost_heat": 7.0, "heat_capacity": 100.0})
	fighter.move_by_gameplay(Vector2.RIGHT, 0.1, 24.0)
	if absf(float(fighter.velocity.x) - 1.0) > 0.001:
		_fail("Fighter move_by_gameplay should consume movement model, got velocity %s." % str(fighter.velocity))
		return
	var boosted := fighter.boost(Vector2.RIGHT, 24.0)
	if not boosted or fighter.boost_drive_timer <= 0.0 or absf(float(fighter.heat) - 7.0) > 0.001:
		_fail("Fighter boost should consume movement model and preserve heat, boosted=%s timer=%.3f heat=%.3f." % [str(boosted), float(fighter.boost_drive_timer), float(fighter.heat)])
		return
	var fighter_source := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	for token in [
		"scripts/services/fighter_movement_model.gd",
		"FighterMovementModel.new",
		"func _movement_model()",
		"_movement_model().movement_drive_intent",
		"_movement_model().boost_intent",
		"_movement_model().velocity_brake_intent",
		"_movement_model().movement_command_intent",
		"_movement_model().thruster_drive_direction",
	]:
		if not fighter_source.contains(token):
			_fail("fighter.gd missing FighterMovementModel boundary token: %s" % token)
			return
	print("FIGHTER_MOVEMENT_MODEL_CONTRACT_PROBE ok drive_x=%.1f boost_heat=%.1f" % [float(fighter.velocity.x), float(fighter.heat)])
	quit(0)
