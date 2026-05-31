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
		"role": "hero",
		"mass": 40.0,
		"engine_momentum_output": 80.0,
		"thruster_allocated_momentum": 30.0,
		"move_efficiency": 1.0,
		"boost_momentum": 0.0,
		"boost_duration": 0.0,
		"bound_limb_allocated_momentum": 20.0,
		"cooling": 20.0,
		"heat_capacity": 40.0,
		"engine_idle_heat": 4.0,
		"booster_idle_heat": 1.0,
		"bound_limb_idle_heat": 1.0,
	}
	main._apply_engine_momentum_budget(stats, "hero")
	main._apply_thruster_momentum_stats(stats, "hero")
	main._apply_thermal_budget(stats, "hero")
	if String(stats.get("engine_momentum_note", "")).begins_with("INVALID"):
		_fail("No Boost capability should not make an otherwise funded unit illegal.")
		return
	if String(stats.get("thermal_note", "")).begins_with("INVALID"):
		_fail("No Boost heat should not affect idle thermal legality.")
		return
	if float(stats.get("boost_speed", 0.0)) != 0.0:
		_fail("No boost extra/duration should show zero Boost speed.")
		return
	print("NO_BOOST_NOT_ILLEGAL_PROBE ok move=%.2f boost=%.2f" % [float(stats.get("body_move_speed", 0.0)), float(stats.get("boost_speed", 0.0))])
	quit()
