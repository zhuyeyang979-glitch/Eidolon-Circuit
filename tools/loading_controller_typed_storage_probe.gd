extends SceneTree

const LoadingTask := preload("res://scripts/services/loading_task.gd")
const LoadingController := preload("res://scripts/controllers/loading_controller.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var controller = LoadingController.new()
	controller.begin("target", "typed_storage")
	controller.add_loading_task(LoadingTask.create("typed", "Typed", 1.0, Callable(), LoadingTask.PHASE_PAGE, true, false))
	controller.add_loading_task({
		"id": "legacy",
		"label": "Legacy",
		"weight": 1.0,
		"phase": LoadingTask.PHASE_IDLE,
		"blocking": false,
		"idle_optional": true,
		"callable": Callable(),
	})
	if controller.tasks.size() != 2:
		_fail("LoadingController should store both typed and legacy-normalized tasks.")
	for task in controller.tasks:
		if not (task is LoadingTask):
			_fail("LoadingController.tasks must store LoadingTask instances, got %s." % typeof(task))
	if controller.tasks[1].id != "legacy" or controller.tasks[1].phase != LoadingTask.PHASE_IDLE:
		_fail("Legacy dictionary should normalize into typed LoadingTask.")
	var defer_controller = LoadingController.new()
	defer_controller.begin("target", "typed_deferred", 0.001, 0.0)
	defer_controller.add_loading_task(LoadingTask.create("idle", "Idle", 1.0, Callable(), LoadingTask.PHASE_IDLE, false, true))
	defer_controller.tick(1, 1.0)
	var deferred := defer_controller.take_deferred_tasks()
	if deferred.size() != 1 or not (deferred[0] is LoadingTask):
		_fail("Deferred loading queue must also store LoadingTask instances.")
	if defer_controller.take_deferred_tasks().size() != 0:
		_fail("take_deferred_tasks should drain deferred typed queue.")
	print("LOADING_CONTROLLER_TYPED_STORAGE_PROBE ok")
	quit(0)
