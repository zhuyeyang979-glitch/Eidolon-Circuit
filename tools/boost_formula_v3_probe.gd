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
		"mass": 20.0,
		"thruster_allocated_momentum": 60.0,
		"move_efficiency": 1.25,
		"boost_momentum": 40.0,
		"boost_efficiency": 2.0,
		"boost_duration": 0.4,
		"brake_efficiency": 1.5,
	}
	main._apply_thruster_momentum_stats(stats, "hero")
	var expected_move := 60.0 * 1.25 / 20.0
	var expected_boost := (60.0 + 40.0) * 2.0 / 20.0
	var expected_brake := 60.0 * 1.5 / 20.0
	if abs(float(stats.get("body_move_speed", 0.0)) - expected_move) > 0.0001:
		_fail("Move speed formula mismatch: got %.4f expected %.4f" % [float(stats.get("body_move_speed", 0.0)), expected_move])
	if abs(float(stats.get("boost_speed", 0.0)) - expected_boost) > 0.0001:
		_fail("Boost speed formula mismatch: got %.4f expected %.4f" % [float(stats.get("boost_speed", 0.0)), expected_boost])
	if abs(float(stats.get("brake_power", 0.0)) - expected_brake) > 0.0001:
		_fail("Brake formula mismatch: got %.4f expected %.4f" % [float(stats.get("brake_power", 0.0)), expected_brake])
	if stats.has("thruster_momentum"):
		_fail("Runtime stats should not expose legacy thruster_momentum")
	print("BOOST_FORMULA_V3_PROBE ok")
	quit()
