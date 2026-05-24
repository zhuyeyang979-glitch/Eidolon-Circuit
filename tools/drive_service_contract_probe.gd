extends SceneTree

const DriveSystemService := preload("res://scripts/services/drive_system_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/services/drive_system_service.gd"))
	if source == "":
		_fail("Could not read DriveSystemService.")
	for token in ["engine_momentum", "bound_limb_allocated_momentum", "thruster_boost_brake_allocated_momentum", "allocated_momentum", "joint_power", "body_move_speed"]:
		if source.find(token) >= 0:
			_fail("DriveSystemService still contains legacy fallback token %s." % token)
	var service := DriveSystemService.new()
	var legacy_only := {
		"engine_momentum_output": 120.0,
		"thruster_boost_brake_allocated_momentum": 20.0,
		"bound_limb_allocated_momentum": 30.0,
	}
	service.apply_drive_contract(legacy_only, "hero")
	if float(legacy_only.get("drive_output_total", -1.0)) != 0.0:
		_fail("Legacy-only engine output was accepted as drive output.")
	if float(legacy_only.get("drive_demand_total", -1.0)) != 0.0:
		_fail("Legacy-only demand was accepted as drive demand.")
	var current := {
		"drive_output_total": 120.0,
		"thruster_drive_demand": 42.0,
		"thruster_boost_extra_demand": 18.0,
		"joint_drive_allocation_total": 24.0,
	}
	service.apply_drive_contract(current, "hero")
	if absf(float(current.get("drive_demand_total", 0.0)) - 84.0) > 0.001:
		_fail("Current drive demand did not merge through service.")
	if not String(current.get("drive_note", "")).begins_with("DRIVE OK"):
		_fail("Current drive contract did not pass: %s" % String(current.get("drive_note", "")))
	print("DRIVE_SERVICE_CONTRACT_PROBE ok demand=%.1f" % float(current.get("drive_demand_total", 0.0)))
	quit()
