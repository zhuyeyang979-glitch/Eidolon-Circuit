extends SceneTree

const LoadingTask := preload("res://scripts/services/loading_task.gd")
const LoadingController := preload("res://scripts/controllers/loading_controller.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var called := {"ok": false}
	var task: LoadingTask = LoadingTask.create(
		"typed",
		"Typed Task",
		2.5,
		func() -> bool:
			called["ok"] = true
			return true,
		LoadingTask.PHASE_FIRST_INTERACTION,
		false,
		false
	)
	if task.id != "typed" or task.label != "Typed Task" or absf(task.weight - 2.5) > 0.001:
		_fail("LoadingTask fixed fields were not stored.")
	if task.phase != LoadingTask.PHASE_FIRST_INTERACTION or task.blocking or task.idle_optional:
		_fail("LoadingTask phase/blocking fields were not stored.")
	if not task.first_interaction_critical():
		_fail("First-interaction phase should be critical.")
	var dict := task.to_dictionary()
	for key in ["id", "label", "weight", "phase", "blocking", "idle_optional", "callable", "essential", "first_interaction_critical"]:
		if not dict.has(key):
			_fail("LoadingTask dictionary missing key: %s" % key)
	var legacy = LoadingTask.from_legacy({"id": "old", "label": "Old", "weight": 1.0, "essential": false, "first_interaction_critical": true, "callable": Callable()})
	if legacy.phase != LoadingTask.PHASE_FIRST_INTERACTION or legacy.blocking:
		_fail("Legacy first-interaction mapping is incorrect.")
	var idle = LoadingTask.from_legacy({"id": "idle", "label": "Idle", "idle_optional": true, "callable": Callable()})
	if idle.phase != LoadingTask.PHASE_IDLE or idle.blocking:
		_fail("Legacy idle mapping is incorrect.")
	if LoadingTask.normalized_phase("unknown") != LoadingTask.PHASE_PAGE:
		_fail("Unknown phases should normalize to page.")
	var controller = LoadingController.new()
	controller.begin("menu", "probe")
	controller.add_loading_task(task)
	if controller.tasks.is_empty():
		_fail("LoadingController did not accept LoadingTask.")
	var stored: Dictionary = controller.tasks[0]
	if String(stored.get("phase", "")) != LoadingTask.PHASE_FIRST_INTERACTION:
		_fail("LoadingController did not preserve task phase.")
	controller.tick(6000, 0.016)
	if not bool(called["ok"]):
		_fail("LoadingController did not execute typed task callable.")
	print("LOADING_TASK_CONTRACT_PROBE ok")
	quit(0)
