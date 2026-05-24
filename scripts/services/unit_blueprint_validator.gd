extends RefCounted
class_name UnitBlueprintValidator

const LEGACY_DRIVE_KEYS := [
	"power",
	"energy",
	"power_load",
	"engine_power",
	"aux_power",
	"required_power",
	"power_margin",
	"engine_torque",
	"engine_motion_scale",
	"engine_momentum_budget",
	"engine_joint_momentum_budget",
	"engine_thruster_momentum_budget",
	"engine_momentum_required",
	"engine_momentum_margin",
	"engine_momentum_ratio",
	"thruster_engine_demand",
	"bound_joint_engine_demand",
	"joint_engine_demand",
	"normal_thrust",
	"boost_power",
	"thruster_momentum",
	"thruster_allocated_momentum",
	"allocated_momentum",
	"body_move_speed",
	"thruster_acceleration",
	"brake_efficiency",
	"recoil_cancel",
	"joint_power",
	"momentum_capacity",
	"load_capacity",
	"embedded_joint_momentum_capacity",
]

const LEGACY_POINTER_KEYS := [
	"attack_groups",
	"action_groups",
	"shell",
	"joint_a",
	"joint_b",
	"muscle_a",
	"muscle_b",
	"visual_pointer",
	"collider_pointer",
]


func legacy_drive_keys() -> Array:
	return LEGACY_DRIVE_KEYS.duplicate()


func legacy_pointer_keys() -> Array:
	return LEGACY_POINTER_KEYS.duplicate()


func has_legacy_drive_data(value: Variant) -> bool:
	return not first_legacy_drive_path(value).is_empty()


func first_legacy_drive_path(value: Variant, path: String = "$") -> String:
	if value is Dictionary:
		var dict: Dictionary = value
		for key in LEGACY_DRIVE_KEYS:
			if dict.has(key):
				return "%s.%s" % [path, key]
		for key in LEGACY_POINTER_KEYS:
			if dict.has(key):
				return "%s.%s" % [path, key]
		for child_key in dict.keys():
			var found := first_legacy_drive_path(dict[child_key], "%s.%s" % [path, str(child_key)])
			if found != "":
				return found
	elif value is Array:
		var arr := Array(value)
		for i in range(arr.size()):
			var found := first_legacy_drive_path(arr[i], "%s[%d]" % [path, i])
			if found != "":
				return found
	return ""
