extends RefCounted
class_name FighterTurnModel


func angle_delta(from_angle: float, to_angle: float) -> float:
	return wrapf(to_angle - from_angle + PI, 0.0, TAU) - PI


func request_facing_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("active", false)):
		return {"allowed": false}
	if float(context.get("melee_stagger_timer", 0.0)) > 0.0:
		return {"allowed": false}
	var direction_sign := int(context.get("direction_sign", 0))
	if direction_sign == 0:
		return {"allowed": false}
	return {
		"allowed": true,
		"target_facing_angle": 0.0 if direction_sign > 0 else PI,
		"turn_direction_bias": 1.0 if direction_sign > 0 else -1.0,
	}


func request_turn_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("active", false)):
		return {"allowed": false}
	if float(context.get("melee_stagger_timer", 0.0)) > 0.0:
		return {"allowed": false}
	var direction_sign := int(context.get("direction_sign", 0))
	var delta := float(context.get("delta", 0.0))
	if direction_sign == 0 or delta <= 0.0:
		return {"allowed": false}
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	var timer := maxf(float(context.get("turn_input_timer", 0.0)), maxf(0.18, delta * 1.2))
	var target := float(context.get("target_facing_angle", 0.0))
	var bias := float(context.get("turn_direction_bias", 0.0))
	var command_rate := maxf(0.0, float(stats.get("turn_command_rate", stats.get("turn_speed", 0.0))))
	if command_rate > 0.0001:
		target = wrapf(target + float(direction_sign) * command_rate * delta, 0.0, TAU)
		bias = float(signi(direction_sign))
	return {
		"allowed": true,
		"turn_input_active": true,
		"turn_input_timer": timer,
		"target_facing_angle": target,
		"turn_direction_bias": bias,
	}


func set_turn_input_active_intent(context: Dictionary) -> Dictionary:
	var is_active := bool(context.get("is_active", false))
	var facing_angle := float(context.get("facing_angle", 0.0))
	return {
		"turn_input_active": is_active,
		"turn_input_timer": maxf(float(context.get("turn_input_timer", 0.0)), 0.18) if is_active else 0.0,
		"target_facing_angle": float(context.get("target_facing_angle", facing_angle)) if is_active else facing_angle,
	}


func turn_brake_acceleration(stats: Dictionary) -> float:
	var brake_power := maxf(0.0, float(stats.get("brake_power", 0.0)))
	var mass := maxf(1.0, float(stats.get("mass", 1.0)))
	var duration := maxf(0.04, float(stats.get("boost_duration", 0.3)))
	var allocated_momentum := maxf(0.0, float(stats.get("move_momentum", 0.0)))
	if allocated_momentum <= 0.0:
		allocated_momentum = maxf(0.0, float(stats.get("boost_momentum", 0.0)))
	var momentum_brake := brake_power / duration
	if momentum_brake <= 0.0:
		momentum_brake = (allocated_momentum / mass) / duration
	var damping_fallback := maxf(0.0, float(stats.get("turn_damping", 0.0)))
	return maxf(maxf(momentum_brake, damping_fallback), 0.1)


func tick_turn_dynamics_intent(context: Dictionary) -> Dictionary:
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	var delta := maxf(0.0, float(context.get("delta", 0.0)))
	var timer := maxf(0.0, float(context.get("turn_input_timer", 0.0)) - delta)
	var input_active := timer > 0.0
	var facing_angle := float(context.get("facing_angle", 0.0))
	var target_facing_angle := float(context.get("target_facing_angle", facing_angle))
	var angular_velocity := float(context.get("angular_velocity", 0.0))
	var turn_direction_bias := float(context.get("turn_direction_bias", 0.0))
	if float(context.get("melee_stagger_timer", 0.0)) > 0.0:
		var stagger_damping := maxf(0.1, float(stats.get("turn_damping", 3.2)))
		angular_velocity = move_toward(angular_velocity, 0.0, stagger_damping * delta * 0.6)
		facing_angle = wrapf(facing_angle + angular_velocity * delta, 0.0, TAU)
		return {
			"turn_input_timer": timer,
			"turn_input_active": input_active,
			"facing_angle": facing_angle,
			"target_facing_angle": target_facing_angle,
			"angular_velocity": angular_velocity,
		}
	var delta_angle := angle_delta(facing_angle, target_facing_angle)
	if absf(absf(delta_angle) - PI) < 0.001 and turn_direction_bias != 0.0:
		delta_angle = turn_direction_bias * PI
	var turn_speed := maxf(0.0, float(stats.get("turn_speed", 0.0)))
	var turn_acceleration := maxf(0.0, float(stats.get("turn_acceleration", 0.0)))
	var turn_damping := maxf(0.0, float(stats.get("turn_damping", 0.0)))
	if turn_speed <= 0.0001 or turn_acceleration <= 0.0001:
		return {
			"turn_input_timer": timer,
			"turn_input_active": input_active,
			"facing_angle": facing_angle,
			"target_facing_angle": target_facing_angle,
			"angular_velocity": 0.0,
		}
	if bool(context.get("overheated", false)) and String(context.get("role", "")) == "hero":
		turn_speed *= 0.62
		turn_acceleration *= 0.58
	var current_state := String(context.get("current_state", "normal"))
	if current_state == "armor":
		turn_speed *= 0.58
		turn_acceleration *= 0.52
	elif current_state == "active":
		turn_speed *= 0.78
		turn_acceleration *= 0.72
	if not input_active:
		var brake_accel := turn_brake_acceleration(stats)
		angular_velocity = move_toward(angular_velocity, 0.0, brake_accel * delta)
		facing_angle = wrapf(facing_angle + angular_velocity * delta, 0.0, TAU)
		target_facing_angle = facing_angle
		if absf(angular_velocity) < 0.002:
			angular_velocity = 0.0
		return {
			"turn_input_timer": timer,
			"turn_input_active": input_active,
			"facing_angle": facing_angle,
			"target_facing_angle": target_facing_angle,
			"angular_velocity": angular_velocity,
		}
	var angular_acceleration := delta_angle * turn_acceleration * 3.2 - angular_velocity * turn_damping
	angular_velocity = clampf(angular_velocity + angular_acceleration * delta, -turn_speed, turn_speed)
	facing_angle = wrapf(facing_angle + angular_velocity * delta, 0.0, TAU)
	if absf(delta_angle) < 0.006 and absf(angular_velocity) < 0.04:
		facing_angle = target_facing_angle
		angular_velocity = 0.0
	return {
		"turn_input_timer": timer,
		"turn_input_active": input_active,
		"facing_angle": facing_angle,
		"target_facing_angle": target_facing_angle,
		"angular_velocity": angular_velocity,
	}
