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
		_fail("Explicit engine output should use the current 9x effective scale.")
	var sample: Dictionary = main._selected_component("hero", "engine", 0)
	var raw := main._engine_momentum_output_raw_for_part(sample)
	var scaled := main._engine_momentum_output_for_part(sample)
	if absf(scaled - raw * MainScene.ENGINE_MOMENTUM_OUTPUT_SCALE) > 0.01:
		_fail("Engine output should be raw * ENGINE_MOMENTUM_OUTPUT_SCALE.")
	print("ENGINE_OUTPUT_EFFECTIVE_SCALE_PROBE ok multiplier=%.1f raw=%.2f scaled=%.2f" % [MainScene.ENGINE_MOMENTUM_OUTPUT_SCALE, raw, scaled])
	quit()
