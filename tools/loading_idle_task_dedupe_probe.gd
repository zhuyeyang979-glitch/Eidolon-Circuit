extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const LoadingTask := preload("res://scripts/services/loading_task.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main.loading_pending_target_state = main.STATE_EDITOR
	main.loading_generation_id = 10
	var task := LoadingTask.create("dup_idle", "Duplicate Idle", 1.0, Callable(), LoadingTask.PHASE_IDLE, false, true, main.STATE_EDITOR, 10)
	main._queue_deferred_loading_idle_tasks([task, task.to_dictionary()])
	if main.loading_idle_tasks.size() != 1:
		_fail("Duplicate idle tasks were not deduped: %d" % main.loading_idle_tasks.size())
	if main.loading_idle_task_deduped_count <= 0:
		_fail("Deduped counter did not increment.")
	main._cleanup_loading_tasks_for_transition(main.STATE_MENU, 11)
	if not main.loading_idle_tasks.is_empty():
		_fail("Stale idle task survived target transition.")
	if main.loading_idle_task_cancelled_stale_count <= 0:
		_fail("Cancelled-stale counter did not increment.")
	print("LOADING_IDLE_TASK_DEDUPE_PROBE ok deduped=%d cancelled=%d" % [
		main.loading_idle_task_deduped_count,
		main.loading_idle_task_cancelled_stale_count,
	])
	quit(0)
