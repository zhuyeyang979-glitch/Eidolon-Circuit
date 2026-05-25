extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var stats := {
		"role": "hero",
		"drive_output_total": 100.0,
		"engine_momentum_output": 100.0,
		"thruster_drive_demand": 20.0,
		"thruster_boost_extra_demand": 30.0,
		"joint_drive_allocation_total": 10.0,
		"engine_idle_heat": 4.0,
		"booster_idle_heat": 2.0,
		"bound_limb_idle_heat": 1.0,
		"boost_heat": 999.0,
		"cooling": 20.0,
		"heat_capacity": 100.0,
	}
	main._apply_drive_budget(stats, "hero")
	main._apply_thermal_budget(stats, "hero")
	if absf(float(stats.get("drive_demand_total", 0.0)) - 60.0) > 0.01:
		_fail("Drive demand should include drive, Boost/brake, and joint demand, but not boost_heat.")
	if String(stats.get("drive_note", "")).begins_with("INVALID"):
		_fail("Large boost_heat should not make drive legality fail.")
	if absf(float(stats.get("idle_heat_load", 0.0)) - 7.0) > 0.01:
		_fail("Idle heat load should exclude boost_heat.")
	if String(stats.get("thermal_note", "")).begins_with("INVALID"):
		_fail("Large boost_heat should not make idle thermal legality fail.")
	print("BOOST_HEAT_NOT_DRIVE_OR_IDLE_LEGALITY_PROBE ok demand=%.1f idle=%.1f" % [float(stats.get("drive_demand_total", 0.0)), float(stats.get("idle_heat_load", 0.0))])
	quit()
