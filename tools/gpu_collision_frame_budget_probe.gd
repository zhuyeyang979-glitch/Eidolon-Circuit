extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _square(center: Vector2, half: float) -> Dictionary:
	return {
		"shape": "polygon",
		"part_kind": "torso",
		"center": center,
		"polygon": [
			center + Vector2(-half, -half),
			center + Vector2(half, -half),
			center + Vector2(half, half),
			center + Vector2(-half, half),
		],
		"bounding_radius": half * 1.42,
		"independent_damage": false,
		"damage_proxy": "torso",
		"gpu_unit_key": 1 if center.x < 0.1 else 2,
		"gpu_team_key": 1 if center.x < 0.1 else 2,
		"gpu_mass": 10.0,
		"gpu_path_stiffness": 100.0,
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if not main._gpu_collision_available():
		_fail("GPU collision unavailable: %s" % main.gpu_collision_status_note)
		return
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if source.contains("compute_contact_responses(") and not source.contains("compute_contact_responses_deferred"):
		_fail("Runtime source does not prefer deferred GPU contact responses.")
		return
	var pipeline = main.gpu_collision_pipeline
	if pipeline == null or not pipeline.is_available():
		_fail("Main GPU pipeline unavailable after initialization: %s" % main.gpu_collision_status_note)
		return
	var colliders := [_square(Vector2.ZERO, 0.5), _square(Vector2(0.35, 0.0), 0.5)]
	var first: Array = pipeline.compute_contact_responses_deferred(colliders, 0.0, 1.0 / 60.0)
	if not first.is_empty():
		_fail("First deferred GPU contact call should only submit work.")
		return
	var contacts: Array = []
	for attempt in range(4):
		await process_frame
		contacts = pipeline.compute_contact_responses_deferred(colliders, 0.0, 1.0 / 60.0)
		if not contacts.is_empty():
			break
	if contacts.is_empty():
		_fail("GPU collision produced no contacts for overlapping test units.")
		return
	if int(pipeline.deferred_contact_submit_count) < 2 or int(pipeline.deferred_contact_consume_count) < 1:
		_fail("Deferred GPU contact submit/consume counters did not advance.")
		return
	print("GPU_COLLISION_FRAME_BUDGET_PROBE ok submit=%d consume=%d contacts=%d" % [int(pipeline.deferred_contact_submit_count), int(pipeline.deferred_contact_consume_count), contacts.size()])
	quit()
