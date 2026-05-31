extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_training_config(true)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	main._apply_performance_profile("compat_60", false)
	if int(round(MainScene.BATTLE_SIMULATION_FPS)) != 120 or Engine.physics_ticks_per_second != 120:
		_fail("Battle simulation and physics must both be fixed at 120Hz.")
		return
	if Engine.max_fps != 72:
		_fail("Compat render cap should remain 72fps, got %d." % Engine.max_fps)
		return
	var before := int(main.battle_simulation_step_count)
	for _frame in range(72):
		main._tick_battle(1.0 / 72.0)
	var stepped := int(main.battle_simulation_step_count) - before
	if stepped != 120:
		_fail("One second at a 72fps render cadence should execute 120 simulation steps, got %d." % stepped)
		return
	print("BATTLE_FIXED_120HZ_SIMULATION_PROBE ok steps=%d render_cap=%d" % [stepped, Engine.max_fps])
	quit(0)
