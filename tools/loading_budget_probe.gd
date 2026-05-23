extends SceneTree

const LoadingControllerScript := preload("res://scripts/controllers/loading_controller.gd")

var calls := 0


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _task() -> bool:
	calls += 1
	var acc := 0
	for i in range(800):
		acc += i
	return true


func _init() -> void:
	var loader = LoadingControllerScript.new()
	loader.begin("probe", "budget")
	for i in range(5):
		loader.add_task("task_%d" % i, "Task %d" % i, 1.0, Callable(self, "_task"), true)
	var complete := loader.tick(1)
	if complete:
		_fail("Loading budget processed every task in one tiny-budget tick.")
		return
	if calls <= 0 or calls >= 5:
		_fail("Unexpected first tick task count: %d" % calls)
		return
	for _i in range(8):
		if loader.tick(1):
			break
	if loader.active:
		_fail("Loading controller did not eventually finish.")
		return
	if int(loader.overshoot_count) <= 0:
		_fail("Loading controller did not record budget overshoot.")
		return
	print("LOADING_BUDGET_PROBE ok calls=%d ticks=%d overshoot=%d" % [calls, int(loader.tick_count), int(loader.overshoot_count)])
	quit(0)
