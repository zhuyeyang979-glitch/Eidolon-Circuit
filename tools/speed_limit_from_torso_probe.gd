extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_stats(mult: float) -> Dictionary:
	return {
		"mass": 20.0,
		"thruster_momentum": 40.0,
		"boost_momentum": 80.0,
		"boost_duration": 0.3,
		"speedometer_mult": mult,
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var small_limit := _make_stats(0.8)
	var large_limit := _make_stats(1.6)
	main._apply_thruster_momentum_stats(small_limit, "hero")
	main._apply_thruster_momentum_stats(large_limit, "hero")
	var a := float(small_limit.get("speedometer_max_speed", 0.0))
	var b := float(large_limit.get("speedometer_max_speed", 0.0))
	if a <= 0.0 or b <= 0.0:
		_fail("Speedometer max speed should be populated.")
		return
	if b <= a:
		_fail("Torso speedometer multiplier should create different speed caps: %.3f vs %.3f" % [a, b])
		return
	if absf(float(large_limit.get("speed_limit", 0.0)) - b) > 0.001:
		_fail("speed_limit should mirror speedometer_max_speed.")
		return
	print("SPEED_LIMIT_FROM_TORSO_PROBE ok %.3f -> %.3f" % [a, b])
	quit()
