extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const LoadingTask := preload("res://scripts/services/loading_task.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_tasks_typed(tasks: Array, label: String) -> void:
	if tasks.is_empty():
		_fail("%s returned no loading tasks." % label)
	for i in range(tasks.size()):
		var raw_task = tasks[i]
		if not (raw_task is LoadingTask):
			_fail("%s task %d should be LoadingTask, got %s." % [label, i, typeof(raw_task)])
		var task: LoadingTask = raw_task
		if task.id == "" or task.label == "" or task.weight <= 0.0:
			_fail("%s task %d has invalid fixed fields." % [label, i])
		if not [LoadingTask.PHASE_STARTUP, LoadingTask.PHASE_PAGE, LoadingTask.PHASE_FIRST_INTERACTION, LoadingTask.PHASE_IDLE].has(task.phase):
			_fail("%s task %d has invalid phase %s." % [label, i, task.phase])
		if not task.callable.is_valid():
			_fail("%s task %d has invalid callable." % [label, i])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	var groups := {
		"menu": main.preload_menu_content(),
		"teamedit": main.preload_teamedit_content(),
		"saved_units": main.preload_saved_units_content(),
		"settings": main.preload_settings_content(),
		"scout": main.preload_scout_content(),
		"battle": main.preload_battle_content(MainScene.MODE_TRAINING),
	}
	for key in groups.keys():
		_assert_tasks_typed(Array(groups[key]), String(key))
	print("PRELOAD_TASKS_TYPED_PROBE ok groups=%d" % groups.size())
	quit(0)
