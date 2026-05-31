extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var tasks: Array = main.preload_battle_content(MainScene.MODE_TRAINING)
	var ids := {}
	for raw_task in tasks:
		if raw_task is Dictionary:
			ids[String(Dictionary(raw_task).get("id", ""))] = true
	for required in ["battle_gpu", "battle_units", "battle_hud"]:
		if not ids.has(required):
			_fail("Battle preload missing task: %s" % required)
			return
	for raw_task in tasks:
		var task: Dictionary = raw_task
		var callable: Callable = task.get("callable", Callable())
		if callable.is_valid():
			callable.call()
	if DisplayServer.get_name().to_lower() != "headless" and main.gpu_collision_pipeline == null:
		_fail("Headed battle preload did not initialize GPU pipeline.")
		return
	print("BATTLE_PRELOAD_GPU_PROBE ok tasks=%d gpu_status=%s" % [tasks.size(), String(main.gpu_collision_status_note)])
	quit(0)
