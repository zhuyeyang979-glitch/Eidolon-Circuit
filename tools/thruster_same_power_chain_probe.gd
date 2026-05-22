extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _stats(allocation: float, mass: float) -> Dictionary:
	return {
		"role": "hero",
		"mass": mass,
		"thruster_allocated_momentum": allocation,
		"move_efficiency": 1.2,
		"boost_efficiency": 2.4,
		"boost_momentum": 20.0,
		"turn_efficiency": 0.8,
		"boost_duration": 0.3,
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var a := _stats(60.0, 30.0)
	main._apply_thruster_momentum_stats(a, "hero")
	main._apply_turn_stats(a, "hero")
	if absf(float(a.get("body_move_speed", 0.0)) - 2.4) > 0.01:
		_fail("Move speed should be allocated * move_efficiency / mass.")
	if absf(float(a.get("boost_speed", 0.0)) - 6.4) > 0.01:
		_fail("Boost speed should be (allocated + boost extra) * boost_efficiency / mass.")
	var stronger := _stats(90.0, 30.0)
	main._apply_thruster_momentum_stats(stronger, "hero")
	main._apply_turn_stats(stronger, "hero")
	var heavier := _stats(60.0, 60.0)
	main._apply_thruster_momentum_stats(heavier, "hero")
	main._apply_turn_stats(heavier, "hero")
	if float(stronger.get("body_move_speed", 0.0)) <= float(a.get("body_move_speed", 0.0)):
		_fail("Higher allocation should increase movement.")
	if float(heavier.get("body_move_speed", 0.0)) >= float(a.get("body_move_speed", 0.0)):
		_fail("Higher mass should reduce movement.")
	if float(stronger.get("turn_speed", 0.0)) <= float(a.get("turn_speed", 0.0)):
		_fail("Higher allocation should increase turn speed.")
	print("THRUSTER_SAME_POWER_CHAIN_PROBE ok move=%.2f boost=%.2f turn=%.2f" % [float(a.get("body_move_speed", 0.0)), float(a.get("boost_speed", 0.0)), float(a.get("turn_speed", 0.0))])
	quit()
