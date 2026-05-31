extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part_with_demand(demand: float) -> Dictionary:
	return {
		"name": "Range Test Thruster",
		"thruster_family": "cruise_blue",
		"drive_demand": demand,
		"allocated_momentum": 999.0,
		"momentum_min": demand,
		"momentum_max": 80.0,
		"move_efficiency": 1.0,
		"boost_momentum": 100.0,
		"boost_efficiency": 2.0,
		"turn_efficiency": 1.0,
		"movement_profile": "omni",
		"slot_volume_tier": "M",
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var low := main._thruster_with_drive_defaults(_part_with_demand(12.0))
	var ok := main._thruster_with_drive_defaults(_part_with_demand(50.0))
	var high := main._thruster_with_drive_defaults(_part_with_demand(96.0))
	if main._thruster_drive_demand_for_part(low) != 12.0:
		_fail("Fixed thruster demand should use low momentum_min.")
	if main._thruster_drive_demand_for_part(ok) != 50.0:
		_fail("Fixed thruster demand should use in-range momentum_min.")
	if main._thruster_drive_demand_for_part(high) != 96.0:
		_fail("Fixed thruster demand should use high momentum_min.")
	if main._booster_normal_momentum_for_part(ok) != 50.0:
		_fail("Move momentum should be fixed demand * move efficiency.")
	if main._booster_boost_momentum_for_part(ok) != 100.0:
		_fail("Boost momentum should be explicit Boost extra momentum.")
	if main._thruster_boost_total_momentum_for_part(ok) != 300.0:
		_fail("Boost total should be (fixed demand + boost extra) * boost efficiency.")
	print("THRUSTER_MOMENTUM_RANGE_PROBE ok")
	quit()
