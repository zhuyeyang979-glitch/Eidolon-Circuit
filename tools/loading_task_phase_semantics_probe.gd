extends SceneTree

const LoadingTask := preload("res://scripts/services/loading_task.gd")
const LoadingController := preload("res://scripts/controllers/loading_controller.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var blocking := LoadingTask.create("page", "Page", 1.0, Callable(), LoadingTask.PHASE_PAGE, true, false)
	if not blocking.blocks_page() or not blocking.first_interaction_critical():
		_fail("blocking=true should block target page and first interaction.")
	var first_interaction := LoadingTask.create(
		"first",
		"First",
		1.0,
		func() -> bool:
			return false,
		LoadingTask.PHASE_FIRST_INTERACTION,
		false,
		false
	)
	if first_interaction.blocks_page() or not first_interaction.blocks_first_interaction() or not first_interaction.first_interaction_critical():
		_fail("first_interaction phase should block first interaction without blocking page display.")
	var idle := LoadingTask.create("idle", "Idle", 1.0, Callable(), LoadingTask.PHASE_IDLE, false, true)
	if idle.blocks_page() or idle.blocks_first_interaction() or idle.first_interaction_critical():
		_fail("idle_optional task should not block page or first interaction.")
	var controller = LoadingController.new()
	controller.begin("target", "first_interaction_probe", 0.001, 0.0)
	controller.add_loading_task(first_interaction)
	controller.tick(1, 1.0)
	if controller.tasks.is_empty() or controller.deferred_tasks.size() != 0:
		_fail("first_interaction task should not be silently deferred on timeout.")
	if controller.first_interaction_critical_pending_count != 1:
		_fail("first_interaction pending count should record unfinished critical task.")
	var idle_controller = LoadingController.new()
	idle_controller.begin("target", "idle_probe", 0.001, 0.0)
	idle_controller.add_loading_task(idle)
	idle_controller.tick(1, 1.0)
	if not idle_controller.tasks.is_empty() or idle_controller.deferred_tasks.size() != 1:
		_fail("idle_optional task should move to deferred idle queue on forced finish.")
	if idle_controller.forced_finish_count != 1:
		_fail("idle_optional timeout should record a forced finish diagnostic.")
	print("LOADING_TASK_PHASE_SEMANTICS_PROBE ok")
	quit(0)
