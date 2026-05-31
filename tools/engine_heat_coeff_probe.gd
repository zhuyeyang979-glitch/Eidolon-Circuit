extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var engine := {
		"engine_momentum_output": 120.0,
		"engine_heat_coeff": 0.075,
		"idle_heat": 99.0,
	}
	var heat := main._engine_idle_heat_for_part(engine, main._engine_momentum_output_for_part(engine))
	if absf(heat - 9.0) > 0.01:
		_fail("Engine idle heat should be output * engine_heat_coeff, not legacy idle_heat.")
	print("ENGINE_HEAT_COEFF_PROBE ok heat=%.2f" % heat)
	quit()
