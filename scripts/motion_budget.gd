class_name MotionBudget
extends RefCounted


static func estimate_motion_budget(motion_stats: Dictionary, module_part: Dictionary, angle_degrees: float, extension_m: float, fallback_duration: float, state_key: String = "normal") -> Dictionary:
	var chain_length := maxf(0.05, float(motion_stats.get("length", motion_stats.get("chain_length", 0.0))))
	var driven_mass := maxf(0.45, float(motion_stats.get("mass", motion_stats.get("driven_mass", 1.0))))
	var output := maxf(0.0, float(motion_stats.get("output", motion_stats.get("allocated_limb_momentum", 0.0))))
	var module_mult := clampf(float(module_part.get("joint_output_mult", 1.0)), 0.25, 3.0)
	if not module_part.has("joint_output_mult"):
		module_mult = 1.0 + maxf(0.0, float(module_part.get("joint_power_bonus", 0.0))) * 0.05
	var state_mult := 1.0
	if state_key == "armor":
		state_mult = clampf(float(module_part.get("armor_joint_mult", module_part.get("armor_speed_mult", 1.08))), 0.35, 2.4)
	elif state_key == "active":
		state_mult = clampf(float(module_part.get("active_joint_mult", module_part.get("active_speed_mult", 1.14))), 0.35, 2.6)
	var joint_speed := maxf(0.02, output * module_mult * state_mult / driven_mass)
	var angular_distance := chain_length * deg_to_rad(maxf(0.0, angle_degrees))
	var extension_distance := maxf(0.0, extension_m)
	var angular_time := angular_distance / joint_speed if angular_distance > 0.001 else 0.0
	var extension_time := extension_distance / joint_speed if extension_distance > 0.001 else 0.0
	var duration := maxf(angular_time, extension_time)
	if duration <= 0.0:
		duration = maxf(0.12, fallback_duration)
	duration = clampf(duration, 0.12, 6.0)
	var contact_distance := maxf(angular_distance, extension_distance)
	var contact_speed := contact_distance / maxf(0.001, duration)
	return {
		"duration": duration,
		"joint_speed": joint_speed,
		"contact_speed": contact_speed,
		"driven_mass": driven_mass,
		"chain_length": chain_length,
		"angular_time": angular_time,
		"extension_time": extension_time,
	}
