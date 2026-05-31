extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _settle_loading(main) -> void:
	for _i in range(24):
		if main.game_state != main.STATE_LOADING:
			return
		main.tick_loading_tasks(0.1, 1000000)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	_settle_loading(main)
	main.loading_auto_transitions_enabled = false
	main._begin_battle(main.MODE_AI, true, "battle_cleanup_probe")
	await process_frame
	var in_battle: Dictionary = main._ui_lifecycle_snapshot()
	if int(in_battle.get("battle_runtime_count", 0)) <= 0:
		_fail("Probe did not create battle runtime objects: %s" % str(in_battle))
	main._show_menu(true)
	await process_frame
	await process_frame
	var after: Dictionary = main._ui_lifecycle_snapshot()
	if int(after.get("battle_runtime_count", 0)) != 0:
		_fail("Battle runtime count not cleared: %s" % str(after))
	if main.all_units.size() != 0:
		_fail("all_units survived battle cleanup.")
	if main.effects_root != null and main.effects_root.get_child_count() > 1:
		_fail("Combat effects survived battle cleanup: %d" % main.effects_root.get_child_count())
	print("BATTLE_EXIT_RUNTIME_CLEANUP_PROBE ok before=%d effects=%d" % [
		int(in_battle.get("battle_runtime_count", 0)),
		0 if main.effects_root == null else main.effects_root.get_child_count(),
	])
	quit(0)
