extends SceneTree

const LoadingControllerScript := preload("res://scripts/controllers/loading_controller.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var loader = LoadingControllerScript.new()
	loader.begin("menu", "startup", 20.0, 2.0)
	loader.add_task("instant", "Instant", 1.0, Callable(self, "_instant"), true, true, false)
	if loader.tick(6000, 0.5):
		_fail("Startup loading finished before its minimum visible time.")
		return
	for _i in range(4):
		if loader.tick(6000, 0.5):
			break
	if loader.active:
		_fail("Startup loading did not finish after minimum visible time.")
		return
	if float(loader.max_duration_sec) != 20.0 or float(loader.min_visible_sec) != 2.0:
		_fail("Startup budget fields were not retained.")
		return
	loader.begin("editor", "page", 10.0, 0.75)
	loader.add_task("instant_page", "Instant Page", 1.0, Callable(self, "_instant"), true, true, false)
	if loader.tick(6000, 0.5):
		_fail("Page loading finished before its minimum visible time.")
		return
	if not loader.tick(6000, 0.3):
		_fail("Page loading did not finish after minimum visible time.")
		return
	print("LOADING_BUDGET_DURATION_PROBE ok startup=%.1f/%.1f page=%.1f/%.2f" % [20.0, 2.0, 10.0, 0.75])
	quit(0)


func _instant() -> bool:
	return true
