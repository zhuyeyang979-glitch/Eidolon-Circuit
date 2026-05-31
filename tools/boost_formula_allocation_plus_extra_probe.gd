extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var part := {
		"drive_demand": 80.0,
		"momentum_min": 80.0,
		"move_efficiency": 1.0,
		"boost_momentum": 40.0,
		"boost_efficiency": 2.5,
		"boost_duration": 0.3,
	}
	var total := main._thruster_boost_total_momentum_for_part(part)
	if absf(total - 300.0) > 0.01:
		_fail("Boost total should be (allocated + boost extra) * boost efficiency.")
	var stats := {
		"role": "hero",
		"mass": 50.0,
		"thruster_drive_demand": 80.0,
		"thruster_allocated_momentum": 9999.0,
		"thruster_boost_extra_demand": 40.0,
		"thruster_boost_peak_demand": 120.0,
		"engine_momentum_output": 120.0,
		"move_efficiency": 1.0,
		"boost_momentum": 40.0,
		"boost_efficiency": 2.5,
		"boost_duration": 0.3,
	}
	main._apply_engine_momentum_budget(stats, "hero")
	main._apply_thruster_momentum_stats(stats, "hero")
	if absf(float(stats.get("boost_total_momentum", 0.0)) - 300.0) > 0.01:
		_fail("Stats should store full boost total separately from boost extra.")
	if absf(float(stats.get("boost_speed", 0.0)) - 6.0) > 0.01:
		_fail("Boost speed should use full boost total / mass.")
	if absf(float(stats.get("boost_momentum", 0.0)) - 40.0) > 0.01:
		_fail("boost_momentum should remain Boost extra momentum.")
	print("BOOST_FORMULA_ALLOCATION_PLUS_EXTRA_PROBE ok total=%.1f speed=%.2f" % [float(stats["boost_total_momentum"]), float(stats["boost_speed"])])
	quit()
