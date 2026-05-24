extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var ok := {
		"role": "hero",
		"mass": 24.0,
		"drive_output_total": 120.0,
		"thruster_drive_demand": 42.0,
		"thruster_boost_extra_demand": 18.0,
		"joint_drive_allocation_total": 24.0,
		"move_efficiency": 1.0,
		"boost_efficiency": 1.0,
		"boost_duration": 0.3,
	}
	main._apply_drive_budget(ok, "hero")
	main._apply_drive_motion_stats(ok, "hero")
	var required := 42.0 + 18.0 + 24.0
	if absf(float(ok.get("drive_demand_total", 0.0)) - required) > 0.01:
		_fail("Drive demand mismatch: %.2f expected %.2f" % [float(ok.get("drive_demand_total", 0.0)), required])
	if absf(float(ok.get("drive_output_total", 0.0)) - 120.0) > 0.01:
		_fail("Drive output mismatch.")
	if String(ok.get("drive_note", "")).begins_with("INVALID"):
		_fail("Sufficient drive budget was marked invalid: %s" % String(ok.get("drive_note", "")))
	var bad := ok.duplicate(true)
	bad["drive_output_total"] = 36.0
	main._apply_drive_budget(bad, "hero")
	if not String(bad.get("drive_note", "")).begins_with("INVALID"):
		_fail("Insufficient drive budget was not marked invalid: %s" % String(bad.get("drive_note", "")))
	print("DRIVE_BUDGET_TEAMEDIT_PROBE ok demand=%.1f margin=%.1f" % [float(ok.get("drive_demand_total", 0.0)), float(ok.get("drive_margin", 0.0))])
	quit()
