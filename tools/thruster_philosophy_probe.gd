extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _family_parts(main, family: String) -> Array:
	var result: Array = []
	var catalog: Array = main._catalog_for("hero", "booster")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "booster", i)
		if String(part.get("thruster_family", "")).to_lower() == family:
			result.append(part)
	return result


func _max_value(parts: Array, field: String, fallback: float = 0.0) -> float:
	var value := -INF
	for raw in parts:
		var part: Dictionary = raw
		value = maxf(value, float(part.get(field, fallback)))
	return value


func _avg_value(parts: Array, field: String, fallback: float = 0.0) -> float:
	if parts.is_empty():
		return fallback
	var sum := 0.0
	for raw in parts:
		var part: Dictionary = raw
		sum += float(part.get(field, fallback))
	return sum / float(parts.size())


func _avg_normal(main, parts: Array) -> float:
	if parts.is_empty():
		return 0.0
	var sum := 0.0
	for raw in parts:
		var part: Dictionary = raw
		sum += main._booster_normal_momentum_for_part(part)
	return sum / float(parts.size())


func _max_boost_ratio(main, parts: Array) -> float:
	var best := 0.0
	for raw in parts:
		var part: Dictionary = raw
		var normal := maxf(0.001, main._booster_normal_momentum_for_part(part))
		best = maxf(best, main._booster_boost_momentum_for_part(part) / normal)
	return best


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var cruise := _family_parts(main, "cruise_blue")
	var sustain := _family_parts(main, "sustain_yellow")
	var overburn := _family_parts(main, "overburn_red")
	var counter := _family_parts(main, "counter_brake")
	var swarm := _family_parts(main, "swarm_micro")
	var titan := _family_parts(main, "titan_vector")
	for pair in [["cruise_blue", cruise], ["sustain_yellow", sustain], ["overburn_red", overburn], ["counter_brake", counter], ["swarm_micro", swarm], ["titan_vector", titan]]:
		if Array(pair[1]).is_empty():
			_fail("Family has no thrusters: %s" % String(pair[0]))
	if not failed:
		if _avg_normal(main, cruise) <= _avg_normal(main, sustain):
			_fail("cruise_blue should have stronger ordinary push than sustain_yellow on average")
		if _max_value(sustain, "boost_duration", 0.0) <= _max_value(cruise, "boost_duration", 0.0):
			_fail("sustain_yellow should expose longer boost duration than cruise_blue")
		if _max_boost_ratio(main, overburn) <= _max_boost_ratio(main, cruise):
			_fail("overburn_red should have a clearer burst ratio than cruise_blue")
		if _max_value(counter, "brake_efficiency", 1.0) <= _max_value(cruise, "brake_efficiency", 1.0):
			_fail("counter_brake should lead brake efficiency")
		if _max_value(counter, "recoil_cancel", 0.0) <= _max_value(cruise, "recoil_cancel", 0.0):
			_fail("counter_brake should lead recoil cancellation")
		if _avg_value(swarm, "mass", 999.0) >= _avg_value(cruise, "mass", 0.0):
			_fail("swarm_micro should be lighter than cruise_blue on average")
		if _avg_value(titan, "mass", 0.0) <= _avg_value(cruise, "mass", 999.0):
			_fail("titan_vector should be heavier than cruise_blue on average")
		if _max_value(titan, "recoil_cancel", 0.0) < 1.2:
			_fail("titan_vector should support heavy reaction control")
	if failed:
		quit(1)
		return
	print("THRUSTER_PHILOSOPHY_PROBE ok cruise=%.1f sustain_dur=%.2f overburn_ratio=%.2f counter_brake=%.2f" % [
		_avg_normal(main, cruise),
		_max_value(sustain, "boost_duration", 0.0),
		_max_boost_ratio(main, overburn),
		_max_value(counter, "brake_efficiency", 1.0),
	])
	quit()
