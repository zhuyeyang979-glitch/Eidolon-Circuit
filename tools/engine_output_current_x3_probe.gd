extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var explicit := {"engine_momentum_output": 10.0}
	if absf(main._engine_momentum_output_for_part(explicit) - 90.0) > 0.001:
		_fail("Explicit engine output should now be raw * 9, i.e. 3x the previous effective value.")
	var budget := {"engine_momentum_budget": 7.0}
	if absf(main._engine_momentum_output_for_part(budget) - 63.0) > 0.001:
		_fail("Legacy engine budget output should now be raw * 9.")
	var sample: Dictionary = main._selected_component("hero", "engine", 0)
	var raw := main._engine_momentum_output_raw_for_part(sample)
	var scaled := main._engine_momentum_output_for_part(sample)
	if raw <= 0.0:
		_fail("Sample engine raw output is zero.")
	if absf(scaled - raw * 9.0) > 0.01:
		_fail("Catalog engine output mismatch: raw %.3f scaled %.3f" % [raw, scaled])
	var stats := {"role": "hero", "mass": 24.0}
	main._merge_engine_stats(stats, sample)
	if absf(float(stats.get("engine_momentum_output", 0.0)) - scaled) > 0.01:
		_fail("Stats merge did not use raw * 9 scaled engine output.")
	print("ENGINE_OUTPUT_CURRENT_X3_PROBE ok raw=%.2f scaled=%.2f" % [raw, scaled])
	quit()
