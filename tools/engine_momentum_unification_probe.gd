extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var engine: Dictionary = main._selected_component("hero", "engine", 0)
	if not engine.has("engine_momentum_output"):
		_fail("Engine is missing engine_momentum_output.")
		return
	for old_key in ["power", "engine_power", "required_power", "engine_torque", "engine_motion_scale", "idle_heat"]:
		if engine.has(old_key):
			_fail("Engine selected component still exposes legacy key: %s" % old_key)
			return
	var stats := {"role": "hero", "mass": 32.0}
	main._merge_engine_stats(stats, engine)
	if float(stats.get("engine_momentum_output", 0.0)) <= 0.0:
		_fail("Engine merge did not add momentum output.")
		return
	for old_stat in ["power", "engine_power", "required_power", "engine_torque", "engine_motion_scale"]:
		if stats.has(old_stat):
			_fail("Engine merge still writes legacy stat: %s" % old_stat)
			return
	main._apply_engine_momentum_budget(stats, "hero")
	if float(stats.get("engine_momentum_output", 0.0)) <= 0.0:
		_fail("Momentum budget lost engine output.")
		return
	print("ENGINE_MOMENTUM_UNIFICATION_PROBE ok output=%.1f heat_coeff=%.3f" % [
		float(engine.get("engine_momentum_output", 0.0)),
		float(engine.get("engine_heat_coeff", 0.0)),
	])
	quit()
