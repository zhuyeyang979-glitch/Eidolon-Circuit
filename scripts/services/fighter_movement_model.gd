extends RefCounted
class_name FighterMovementModel

const MOVE_COMMAND_NONE := "none"
const MOVE_COMMAND_DRIVE := "drive"
const MOVE_COMMAND_BRAKE := "brake"


func has_bidirectional_thrusters(stats: Dictionary) -> bool:
	if bool(stats.get("bidirectional_thrusters", false)):
		return true
	var mount := String(stats.get("thruster_mount", stats.get("booster_mount", ""))).to_lower()
	return mount.contains("front_back") or mount.contains("omni") or mount.contains("bidirectional")


func speedometer_max_speed(stats: Dictionary) -> float:
	var explicit_limit := maxf(0.0, float(stats.get("speedometer_max_speed", 0.0)))
	if explicit_limit > 0.001:
		return explicit_limit
	var body_speed := maxf(0.0, float(stats.get("move_speed", 0.0)))
	var boost_speed := maxf(0.0, float(stats.get("boost_speed", 0.0)))
	return maxf(1.0, maxf(body_speed * 3.0, boost_speed * 2.0) * 1.5)


func brake_delta_velocity(stats: Dictionary) -> float:
	var brake_power := maxf(0.0, float(stats.get("brake_power", 0.0)))
	if brake_power > 0.0:
		return brake_power
	var allocated_momentum := maxf(0.0, float(stats.get("move_momentum", 0.0)))
	if allocated_momentum <= 0.0:
		allocated_momentum = maxf(0.0, float(stats.get("boost_momentum", 0.0)))
	var mass := maxf(1.0, float(stats.get("mass", 1.0)))
	return allocated_momentum / mass


func boost_brake_acceleration(stats: Dictionary) -> float:
	var boost_duration := maxf(0.04, float(stats.get("boost_duration", 0.3)))
	return brake_delta_velocity(stats) / boost_duration


func can_velocity_brake(current_velocity: Vector2, stats: Dictionary) -> bool:
	return current_velocity.length() > 0.001 and brake_delta_velocity(stats) > 0.001


func direction_inside_thruster_cone(desired: Vector2, forward: Vector2, side: Vector2, cone_degrees: float) -> Vector2:
	if desired.length() <= 0.04:
		return Vector2.ZERO
	var desired_dir := desired.normalized()
	var forward_dir := forward.normalized() if forward.length() > 0.001 else Vector2.RIGHT
	var side_dir := side.normalized() if side.length() > 0.001 else Vector2(-forward_dir.y, forward_dir.x)
	var forward_component := desired_dir.dot(forward_dir)
	var side_component := desired_dir.dot(side_dir)
	cone_degrees = clampf(cone_degrees, 20.0, 360.0)
	if cone_degrees >= 359.0:
		return desired_dir
	var cone_cos := cos(deg_to_rad(cone_degrees * 0.5))
	if forward_component >= cone_cos:
		return desired_dir
	if cone_degrees >= 179.0:
		if absf(side_component) <= 0.001:
			return Vector2.ZERO
		return (side_dir * side_component).normalized()
	var side_sign := signf(side_component)
	if side_sign == 0.0:
		return Vector2.ZERO
	var clamped := forward_dir * cone_cos + side_dir * side_sign * sqrt(maxf(0.0, 1.0 - cone_cos * cone_cos))
	return clamped.normalized()


func thruster_drive_direction(context: Dictionary) -> Vector2:
	var requested: Vector2 = context.get("requested", Vector2.ZERO)
	if requested.length() <= 0.04:
		return Vector2.ZERO
	var desired := requested.normalized()
	if bool(context.get("has_runtime_topology", false)):
		return desired
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	if has_bidirectional_thrusters(stats):
		return desired
	return direction_inside_thruster_cone(desired, Vector2(context.get("forward", Vector2.RIGHT)), Vector2(context.get("side", Vector2.UP)), float(stats.get("thruster_cone_degrees", 180.0)))


func thruster_boost_direction(context: Dictionary) -> Vector2:
	var requested: Vector2 = context.get("requested", Vector2.ZERO)
	if requested.length() <= 0.04:
		return Vector2.ZERO
	var desired := requested.normalized()
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	var forward := Vector2(context.get("forward", Vector2.RIGHT)).normalized()
	var profile := String(stats.get("movement_profile", "omni")).to_lower()
	if profile == "car" and desired.dot(forward) <= 0.0:
		return Vector2.ZERO
	var boost_angle := clampf(float(stats.get("boost_angle_degrees", 360.0)), 20.0, 360.0)
	if boost_angle >= 359.0:
		return desired
	var cone_cos := cos(deg_to_rad(boost_angle * 0.5))
	return desired if desired.dot(forward) >= cone_cos else Vector2.ZERO


func rear_brake_zone(input_dir: Vector2, forward: Vector2, rear_half_angle_degrees: float) -> bool:
	if input_dir.length() <= 0.04:
		return false
	var forward_dir := forward.normalized() if forward.length() > 0.001 else Vector2.RIGHT
	var rear_dot := input_dir.normalized().dot(-forward_dir)
	var rear_limit := cos(deg_to_rad(rear_half_angle_degrees))
	return rear_dot >= rear_limit


func reverse_drive_allowed(context: Dictionary) -> bool:
	var input_vector: Vector2 = context.get("input_vector", Vector2.ZERO)
	var ready_dir: Vector2 = context.get("brake_reverse_ready_dir", Vector2.ZERO)
	if input_vector.length() <= 0.04:
		return false
	if float(context.get("brake_reverse_ready_timer", 0.0)) <= 0.0 or ready_dir.length() <= 0.04:
		return false
	if bool(context.get("brake_reverse_requires_repress", false)):
		return false
	return input_vector.normalized().dot(ready_dir.normalized()) >= float(context.get("brake_reverse_dir_dot", 0.82))


func brake_reverse_waiting_for_repress(context: Dictionary) -> bool:
	var input_vector: Vector2 = context.get("input_vector", Vector2.ZERO)
	var ready_dir: Vector2 = context.get("brake_reverse_ready_dir", Vector2.ZERO)
	if input_vector.length() <= 0.04:
		return false
	if float(context.get("brake_reverse_ready_timer", 0.0)) <= 0.0 or ready_dir.length() <= 0.04:
		return false
	if not bool(context.get("brake_reverse_requires_repress", false)):
		return false
	return input_vector.normalized().dot(ready_dir.normalized()) >= float(context.get("brake_reverse_dir_dot", 0.82))


func input_should_velocity_brake(context: Dictionary) -> bool:
	var input_vector: Vector2 = context.get("input_vector", Vector2.ZERO)
	var current_velocity: Vector2 = context.get("velocity", Vector2.ZERO)
	if input_vector.length() <= 0.04 or current_velocity.length() <= 0.01:
		return false
	if reverse_drive_allowed(context):
		return false
	return input_vector.normalized().dot(current_velocity.normalized()) <= -0.12


func boost_request_is_reverse_only(context: Dictionary) -> bool:
	var input_vector: Vector2 = context.get("input_vector", Vector2.ZERO)
	if input_vector.length() <= 0.04:
		return false
	if reverse_drive_allowed(context) or brake_reverse_waiting_for_repress(context):
		return true
	return rear_brake_zone(input_vector, Vector2(context.get("forward", Vector2.RIGHT)), float(context.get("rear_brake_half_angle_degrees", 50.0)))


func velocity_brake_intent(context: Dictionary) -> Dictionary:
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	var current_velocity: Vector2 = context.get("velocity", Vector2.ZERO)
	if not can_velocity_brake(current_velocity, stats):
		return {"allowed": false}
	var old_dir := current_velocity.normalized()
	var step := brake_delta_velocity(stats) if bool(context.get("full_boost", false)) else boost_brake_acceleration(stats) * maxf(0.0, float(context.get("delta", 0.0)))
	step = minf(current_velocity.length(), step)
	if step <= 0.0001:
		return {"allowed": false}
	var next_velocity := current_velocity - old_dir * step
	var stopped := false
	if next_velocity.length() < 0.001 or next_velocity.dot(old_dir) <= 0.0:
		next_velocity = Vector2.ZERO
		stopped = true
	var reason := String(context.get("reason", ""))
	var input_dir: Vector2 = context.get("input_dir", Vector2.ZERO)
	var should_set_reverse_ready := stopped and (reason.begins_with("unusable_") or reason == "reverse_brake") and input_dir.length() > 0.04
	return {
		"allowed": true,
		"velocity": next_velocity,
		"old_dir": old_dir,
		"brake_step": step,
		"stopped": stopped,
		"thruster_output_direction": -old_dir,
		"thruster_visual_timer": 0.18,
		"boost_flash_timer": 0.16,
		"set_reverse_ready": should_set_reverse_ready,
		"reverse_ready_dir": input_dir.normalized() if should_set_reverse_ready else Vector2.ZERO,
	}


func movement_command_intent(context: Dictionary) -> Dictionary:
	var input_vector: Vector2 = context.get("input_vector", Vector2.ZERO)
	if input_vector.length() <= 0.04:
		return {"mode": MOVE_COMMAND_NONE, "meta_mode": "none", "drive_dir": Vector2.ZERO}
	if reverse_drive_allowed(context):
		return {"mode": MOVE_COMMAND_DRIVE, "meta_mode": "reverse", "drive_dir": input_vector.normalized()}
	if brake_reverse_waiting_for_repress(context):
		return {"mode": MOVE_COMMAND_NONE, "meta_mode": "none", "drive_dir": Vector2.ZERO}
	var can_brake := can_velocity_brake(Vector2(context.get("velocity", Vector2.ZERO)), Dictionary(context.get("stats", {})))
	if input_should_velocity_brake(context):
		return {"mode": MOVE_COMMAND_BRAKE if can_brake else MOVE_COMMAND_NONE, "meta_mode": "brake" if can_brake else "none", "drive_dir": Vector2.ZERO}
	var drive_context := context.duplicate()
	drive_context["requested"] = input_vector
	var drive_dir := thruster_drive_direction(drive_context)
	if drive_dir.length() > 0.04:
		return {"mode": MOVE_COMMAND_DRIVE, "meta_mode": "drive", "drive_dir": drive_dir.normalized()}
	return {"mode": MOVE_COMMAND_BRAKE if can_brake else MOVE_COMMAND_NONE, "meta_mode": "brake" if can_brake else "none", "drive_dir": Vector2.ZERO}


func movement_drive_intent(context: Dictionary) -> Dictionary:
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	var desired: Vector2 = context.get("input_vector", Vector2.ZERO)
	var role := String(context.get("role", ""))
	if not bool(context.get("active", false)):
		return {"allowed": false, "gate_reason": "inactive"}
	if role == "barrier":
		return {"allowed": false, "gate_reason": "barrier"}
	if float(context.get("melee_stagger_timer", 0.0)) > 0.0:
		return {"allowed": false, "gate_reason": "stagger"}
	if float(context.get("cooling_lock_timer", 0.0)) > 0.0:
		return {"allowed": false, "gate_reason": "overheat_shutdown" if bool(context.get("overheated", false)) or float(context.get("forced_cooling_timer", 0.0)) > 0.0 else "cooling_lock"}
	if desired.length() <= 0.04:
		return {"allowed": false, "gate_reason": "no_input", "meta_mode": "none"}
	if desired.length() > 1.0:
		desired = desired.normalized()
	if float(context.get("module_clamp_pin_timer", 0.0)) > 0.0:
		desired *= clampf(float(context.get("module_clamp_velocity_mult", 1.0)), 0.05, 1.0)
	var command_context := context.duplicate()
	command_context["input_vector"] = desired
	var command := movement_command_intent(command_context)
	var mode := String(command.get("mode", MOVE_COMMAND_NONE))
	if mode == MOVE_COMMAND_NONE:
		return {"allowed": false, "gate_reason": "unusable_direction", "mode": mode, "meta_mode": String(command.get("meta_mode", "none"))}
	if mode == MOVE_COMMAND_BRAKE:
		return {"allowed": false, "gate_reason": "braking", "mode": mode, "meta_mode": String(command.get("meta_mode", "brake")), "brake_input": desired}
	var drive_dir: Vector2 = command.get("drive_dir", Vector2.ZERO)
	if drive_dir.length() <= 0.04:
		return {"allowed": false, "gate_reason": "unusable_direction", "mode": mode, "meta_mode": "none"}
	drive_dir = drive_dir.normalized()
	var speed := float(stats.get("move_speed", 0.0))
	if bool(context.get("overheated", false)) and role == "hero":
		speed *= 0.58
	var current_state := String(context.get("current_state", "normal"))
	if current_state == "armor":
		speed *= 0.48
	elif current_state == "active":
		speed *= 0.72
	var acceleration := float(stats.get("move_acceleration", 0.0))
	if speed <= 0.0001 or acceleration <= 0.0001:
		return {"allowed": false, "gate_reason": "no_drive", "mode": mode, "meta_mode": String(command.get("meta_mode", "drive")), "drive_dir": drive_dir}
	var cornering := maxf(0.35, float(stats.get("cornering", 1.0)))
	if float(context.get("recovery_boost_timer", 0.0)) > 0.0:
		var recovery_response := float(context.get("recovery_response", 1.0))
		acceleration *= recovery_response
		cornering *= clampf(0.7 + recovery_response * 0.3, 0.62, 1.22)
	var current_velocity: Vector2 = context.get("velocity", Vector2.ZERO)
	var delta := maxf(0.0, float(context.get("delta", 0.0)))
	var target_velocity := Vector2(drive_dir.x * speed, drive_dir.y * speed)
	var needed_delta := target_velocity - current_velocity
	var next_velocity := current_velocity
	if needed_delta.length() > 0.001:
		next_velocity += needed_delta.limit_length(acceleration * cornering * delta)
	return {
		"allowed": true,
		"gate_reason": "",
		"mode": mode,
		"meta_mode": String(command.get("meta_mode", "drive")),
		"input_vector": desired,
		"drive_dir": drive_dir,
		"velocity": next_velocity,
		"clear_reverse_ready": not reverse_drive_allowed(command_context),
		"thruster_visual_timer": 0.16,
	}


func boost_intent(context: Dictionary) -> Dictionary:
	var direction: Vector2 = context.get("direction", Vector2.ZERO)
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	if not bool(context.get("active", false)) or String(context.get("role", "")) != "hero" or direction.length() < 0.1 or float(context.get("cooling_lock_timer", 0.0)) > 0.0:
		return {"allowed": false, "reason": "gate"}
	if float(context.get("melee_stagger_timer", 0.0)) > 0.0:
		return {"allowed": false, "reason": "stagger"}
	if float(context.get("boost_cooldown_timer", 0.0)) > 0.0:
		return {"allowed": false, "reason": "cooldown"}
	var reverse_context := context.duplicate()
	reverse_context["input_vector"] = direction
	if boost_request_is_reverse_only(reverse_context):
		return {"allowed": false, "reason": "reverse_only", "should_brake": can_velocity_brake(Vector2(context.get("velocity", Vector2.ZERO)), stats), "brake_reason": "reverse_brake"}
	if brake_reverse_waiting_for_repress(reverse_context) or input_should_velocity_brake(reverse_context):
		return {"allowed": false, "reason": "reverse_brake", "should_brake": true, "brake_reason": "reverse_brake"}
	var boost_extra_demand := maxf(0.0, float(stats.get("thruster_boost_extra_demand", 0.0)))
	var boost_total_momentum := maxf(0.0, float(stats.get("boost_total_momentum", stats.get("boost_momentum", 0.0))))
	var boost_speed := maxf(0.0, float(stats.get("boost_speed", 0.0)))
	var boost_duration := maxf(0.0, float(stats.get("boost_duration", 0.0)))
	if boost_extra_demand <= 0.0 or boost_duration <= 0.0 or (boost_total_momentum <= 0.0 and boost_speed <= 0.0):
		return {"allowed": false, "reason": "no_boost"}
	var boost_dir := thruster_boost_direction({
		"requested": direction,
		"stats": stats,
		"forward": context.get("forward", Vector2.RIGHT),
	})
	if boost_dir.length() <= 0.04:
		return {"allowed": false, "reason": "unusable_boost_angle", "should_brake": true, "brake_reason": "unusable_boost_angle"}
	boost_dir = boost_dir.normalized()
	var current_velocity: Vector2 = context.get("velocity", Vector2.ZERO)
	var recovery_return := float(context.get("recovery_boost_timer", 0.0)) > 0.0 and current_velocity.length() > 0.08 and boost_dir.dot(-current_velocity.normalized()) > 0.18
	var mass := maxf(1.0, float(stats.get("mass", 1.0)))
	var max_delta_v := boost_total_momentum / mass
	if boost_speed > 0.0:
		max_delta_v = maxf(max_delta_v, boost_speed - maxf(0.0, current_velocity.dot(boost_dir)))
	if recovery_return:
		max_delta_v *= 1.08 + float(context.get("recovery_response", 0.85)) * 0.22
	elif float(context.get("recovery_boost_timer", 0.0)) > 0.0:
		max_delta_v *= clampf(0.82 + float(context.get("recovery_response", 0.85)) * 0.18, 0.72, 1.16)
	if max_delta_v <= 0.001:
		return {"allowed": false, "reason": "no_delta_v"}
	boost_duration = maxf(0.04, boost_duration)
	var flash_duration := 0.34 if recovery_return else 0.18
	if String(stats.get("thruster_family", "")).to_lower() == "overburn_red":
		flash_duration += 0.12
	flash_duration = maxf(flash_duration, boost_duration)
	return {
		"allowed": true,
		"boost_dir": boost_dir,
		"boost_duration": boost_duration,
		"delta_v": max_delta_v,
		"velocity_remaining": boost_dir * max_delta_v,
		"projection_guard_timer": boost_duration + 0.18,
		"projection_guard_direction": boost_dir,
		"flash_duration": flash_duration,
		"recovery_return": recovery_return,
		"heat": maxf(0.0, float(stats.get("boost_heat", 0.0))),
		"cooldown": maxf(0.0, float(stats.get("boost_cooldown", float(context.get("boost_cooldown_default", 0.5))))),
	}
