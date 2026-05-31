extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _stats(mass: float) -> Dictionary:
	return {
		"role": "hero",
		"mass": mass,
		"thruster_drive_demand": 60.0,
		"thruster_allocated_momentum": 9999.0,
		"thruster_boost_extra_demand": 40.0,
		"thruster_boost_peak_demand": 100.0,
		"engine_momentum_output": 100.0,
		"move_efficiency": 1.1,
		"boost_efficiency": 2.2,
		"boost_momentum": 40.0,
		"boost_duration": 0.3,
		"speed_mult": 1.0,
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var light := _stats(20.0)
	var heavy := _stats(60.0)
	main._apply_engine_momentum_budget(light, "hero")
	main._apply_thruster_momentum_stats(light, "hero")
	main._apply_turn_stats(light, "hero")
	main._apply_engine_momentum_budget(heavy, "hero")
	main._apply_thruster_momentum_stats(heavy, "hero")
	main._apply_turn_stats(heavy, "hero")
	if float(light.get("move_momentum", 0.0)) <= 0.0 or float(light.get("boost_total_momentum", 0.0)) <= 0.0:
		_fail("Fixed thruster demand should produce move and boost momentum.")
	if absf(float(light.get("thruster_allocated_momentum", 0.0)) - 60.0) > 0.001:
		_fail("Fixed thruster demand should override legacy allocation alias.")
	if float(light.get("body_move_speed", 0.0)) <= float(heavy.get("body_move_speed", 0.0)):
		_fail("Same fixed thruster demand should move lighter mechs faster.")
	if float(light.get("turn_speed", 0.0)) <= float(heavy.get("turn_speed", 0.0)):
		_fail("Same fixed thruster demand should turn lighter mechs faster.")
	print("THRUSTER_FIXED_DEMAND_MOTION_PROBE ok light=%.3f heavy=%.3f" % [float(light.get("body_move_speed", 0.0)), float(heavy.get("body_move_speed", 0.0))])
	quit()
