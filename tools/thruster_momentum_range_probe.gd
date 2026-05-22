extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part_with_allocation(allocation: float) -> Dictionary:
	return {
		"name": "Range Test Thruster",
		"thruster_family": "cruise_blue",
		"allocated_momentum": allocation,
		"momentum_min": 20.0,
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
	var low := main._thruster_with_drive_defaults(_part_with_allocation(12.0))
	var ok := main._thruster_with_drive_defaults(_part_with_allocation(50.0))
	var high := main._thruster_with_drive_defaults(_part_with_allocation(96.0))
	if float(low.get("allocated_momentum", 0.0)) >= float(low.get("momentum_min", 0.0)):
		_fail("Low thruster allocation should be below min.")
	if float(ok.get("allocated_momentum", 0.0)) < float(ok.get("momentum_min", 0.0)) or float(ok.get("allocated_momentum", 0.0)) > float(ok.get("momentum_max", 0.0)):
		_fail("In-range thruster allocation should be valid.")
	if float(high.get("allocated_momentum", 0.0)) <= float(high.get("momentum_max", 0.0)):
		_fail("High thruster allocation should exceed max.")
	if main._booster_normal_momentum_for_part(ok) != 50.0:
		_fail("Move momentum should be allocated power * move efficiency.")
	if main._booster_boost_momentum_for_part(ok) != 100.0:
		_fail("Boost momentum should be explicit Boost extra momentum.")
	if main._thruster_boost_total_momentum_for_part(ok) != 300.0:
		_fail("Boost total should be (allocated + boost extra) * boost efficiency.")
	print("THRUSTER_MOMENTUM_RANGE_PROBE ok")
	quit()
