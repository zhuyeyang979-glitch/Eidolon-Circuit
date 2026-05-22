extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._apply_performance_profile("compat_60", false)
	main._reset_battle_vfx_frame_budget()
	var accepted := 0
	for i in range(200):
		if main._consume_battle_vfx_budget("projectile_trace"):
			accepted += 1
	var limit := int(main._runtime_quality_value("projectile_trace_budget", 0))
	if accepted != limit:
		_fail("Projectile trace budget accepted %d, expected %d." % [accepted, limit])
		return
	if int(main.battle_vfx_budget_drop_count) <= 0:
		_fail("Budget overflow did not record dropped VFX.")
		return
	print("BATTLE_VFX_BUDGET_PROBE ok accepted=%d dropped=%d" % [accepted, int(main.battle_vfx_budget_drop_count)])
	quit(0)
