extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var booster := {
		"thruster_family": "cruise_blue",
		"drive_demand": 20.0,
		"momentum_min": 20.0,
		"momentum_max": 80.0,
		"boost_momentum": 60.0,
		"boost_brake_momentum_min": 10.0,
		"boost_brake_momentum_max": 90.0,
		"thruster_idle_heat_coeff": 0.02,
	}
	var payload := {
		"thruster_drive_allocated_momentum": 30.0,
		"thruster_boost_brake_allocated_momentum": 70.0,
	}
	var stats := {}
	main._merge_thruster_drive_stats(stats, booster, payload)
	var expected_idle := 30.0 * 0.02
	if absf(float(stats.get("booster_idle_heat", 0.0)) - expected_idle) > 0.001:
		_fail("Booster idle heat should only count move drive demand. expected %.3f got %.3f" % [expected_idle, float(stats.get("booster_idle_heat", 0.0))])
	if absf(float(stats.get("thruster_boost_extra_demand", 0.0)) - 70.0) > 0.001:
		_fail("Boost/brake peak demand should remain in the engine demand chain.")
	if absf(float(stats.get("thruster_boost_peak_demand", 0.0)) - 100.0) > 0.001:
		_fail("Boost peak demand should be drive + boost/brake demand.")
	print("BOOST_PEAK_NO_IDLE_HEAT_PROBE ok idle=%.3f peak=%.1f" % [float(stats.get("booster_idle_heat", 0.0)), float(stats.get("thruster_boost_peak_demand", 0.0))])
	quit()
