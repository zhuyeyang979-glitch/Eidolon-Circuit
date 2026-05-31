extends RefCounted
class_name DriveSystemService

const CONTRACT_KEYS := [
	"drive_output_total",
	"drive_demand_total",
	"drive_margin",
	"drive_ratio",
	"move_speed",
	"move_acceleration",
	"boost_speed",
	"boost_momentum",
	"boost_duration",
	"brake_power",
	"reaction_cancel",
	"action_drive_scale",
	"stability_drive_scale",
]


func contract_keys() -> Array:
	return CONTRACT_KEYS.duplicate()


func apply_drive_contract(stats: Dictionary, role_key: String = "") -> Dictionary:
	var output := maxf(0.0, float(stats.get("drive_output_total", 0.0)))
	var thruster_demand := maxf(0.0, float(stats.get("thruster_drive_demand", 0.0)))
	var boost_demand := maxf(0.0, float(stats.get("thruster_boost_extra_demand", 0.0)))
	var joint_demand := maxf(0.0, float(stats.get("joint_drive_allocation_total", 0.0)))
	var component_demand := thruster_demand + boost_demand + joint_demand
	var demand := maxf(0.0, float(stats.get("drive_demand_total", 0.0)))
	if component_demand > 0.0 or not stats.has("drive_demand_total"):
		demand = component_demand
	var ratio := output / maxf(1.0, demand)
	if role_key == "barrier" and output <= 0.0 and demand <= 0.0:
		ratio = 1.0
	stats["drive_output_total"] = output
	stats["drive_demand_total"] = demand
	stats["drive_margin"] = output - demand
	stats["drive_ratio"] = ratio
	stats["action_drive_scale"] = clampf(sqrt(maxf(0.16, ratio)), 0.42, 1.35)
	stats["stability_drive_scale"] = clampf(0.62 + ratio * 0.38, 0.42, 1.28)
	stats["reaction_cancel"] = maxf(0.0, float(stats.get("reaction_cancel", 0.0)))
	for key in ["move_speed", "move_acceleration", "boost_speed", "boost_momentum", "boost_duration", "brake_power"]:
		if not stats.has(key):
			stats[key] = 0.0
	if role_key == "barrier":
		stats["drive_note"] = "BARRIER STATIC: no drive demand." if demand <= 0.0 else "BARRIER DRIVE %.0f / %.0f." % [output, demand]
	elif demand <= 0.0:
		stats["drive_note"] = "DRIVE OK: no thruster or action demand."
	elif output <= 0.0:
		stats["drive_note"] = "INVALID: no drive output for thrusters or bound actions."
	elif output < demand:
		stats["drive_note"] = "INVALID: drive output %.0f < demand %.0f." % [output, demand]
	else:
		stats["drive_note"] = "DRIVE OK: output %.0f covers demand %.0f%s." % [output, demand, " with reserve" if ratio >= 1.18 else ""]
	return stats
