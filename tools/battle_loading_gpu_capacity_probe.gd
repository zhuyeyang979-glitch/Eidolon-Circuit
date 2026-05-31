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
	var found_capacity := false
	for raw_task in tasks:
		if not (raw_task is Dictionary):
			continue
		var task: Dictionary = raw_task
		if String(task.get("id", "")) == "battle_gpu_capacity":
			found_capacity = true
		var callable: Callable = task.get("callable", Callable())
		if callable.is_valid():
			callable.call()
	if not found_capacity:
		_fail("Battle preload missing GPU capacity task.")
		return
	if DisplayServer.get_name().to_lower() != "headless":
		if main.gpu_collision_pipeline == null or not main.gpu_collision_pipeline.available:
			_fail("Headed battle preload did not initialize GPU pipeline.")
			return
		if int(main.gpu_collision_pipeline.collider_buffer_bytes) <= 0 or int(main.gpu_collision_pipeline.query_buffer_bytes) <= 0:
			_fail("Headed battle preload did not prewarm GPU collision/query buffers.")
			return
	print("BATTLE_LOADING_GPU_CAPACITY_PROBE ok tasks=%d gpu=%s" % [tasks.size(), String(main.gpu_collision_status_note)])
	quit(0)
