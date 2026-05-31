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
		"engine_idle_heat": 6.0,
		"booster_idle_heat": 3.0,
		"bound_limb_idle_heat": 1.0,
		"cooling": 11.0,
		"heat_capacity": 40.0,
		"boost_heat": 999.0,
	}
	main._apply_thermal_budget(stats, "hero")
	if String(stats.get("thermal_note", "")).begins_with("INVALID"):
		_fail("Boost heat should not make idle thermal legality fail.")
		return
	if absf(float(stats.get("idle_heat_load", 0.0)) - 10.0) > 0.01:
		_fail("Idle heat load should only include engine, thruster idle, and bound limb idle heat.")
		return
	print("THERMAL_IDLE_VS_BOOST_PROBE ok idle=%.1f margin=%.1f" % [float(stats.get("idle_heat_load", 0.0)), float(stats.get("thermal_margin", 0.0))])
	quit()
