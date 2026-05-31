extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _stats_for_boost_allocation(main, boost_allocation: float) -> Dictionary:
	var part := {
		"name": "Probe Boost Heat Thruster",
		"thruster_family": "cruise_blue",
		"drive_demand": 40.0,
		"momentum_min": 40.0,
		"allocated_momentum": 40.0,
		"move_efficiency": 1.0,
		"boost_momentum": 20.0,
		"boost_efficiency": 2.0,
		"boost_duration": 0.3,
		"boost_heat": 8.0,
		"slot_volume_tier": "S",
	}
	var payload := {
		"kind": "booster",
		"thruster_drive_allocated_momentum": 40.0,
		"thruster_boost_brake_allocated_momentum": boost_allocation,
	}
	var stats := {
		"role": "hero",
		"mass": 20.0,
		"drive_output_total": 500.0,
		"engine_momentum_output": 500.0,
	}
	main._merge_thruster_drive_stats(stats, part, payload)
	main._apply_drive_budget(stats, "hero")
	main._apply_drive_motion_stats(stats, "hero")
	return stats


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var low := _stats_for_boost_allocation(main, 20.0)
	var high := _stats_for_boost_allocation(main, 60.0)
	if float(high.get("boost_speed", 0.0)) <= float(low.get("boost_speed", 0.0)):
		_fail("Higher Boost/brake allocation should increase boost speed.")
	if absf(float(low.get("boost_heat", 0.0)) - 8.0) > 0.001 or absf(float(high.get("boost_heat", 0.0)) - 8.0) > 0.001:
		_fail("Boost heat must stay fixed when Boost/brake allocation changes.")
	if float(high.get("drive_demand_total", 0.0)) <= float(low.get("drive_demand_total", 0.0)):
		_fail("Boost/brake allocation should still participate in drive demand.")
	print("BOOST_HEAT_INDEPENDENT_FROM_DRIVE_ALLOCATION_PROBE ok low=%.2f high=%.2f heat=%.1f" % [float(low.get("boost_speed", 0.0)), float(high.get("boost_speed", 0.0)), float(high.get("boost_heat", 0.0))])
	quit()
