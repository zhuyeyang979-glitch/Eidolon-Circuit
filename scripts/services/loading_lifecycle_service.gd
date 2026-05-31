extends RefCounted
class_name LoadingLifecycleService

const LoadingTask = preload("res://scripts/services/loading_task.gd")


static func prepare_task(raw_task: Variant, target_page: String, generation_id: int) -> LoadingTask:
	var task: LoadingTask = LoadingTask.from_legacy(raw_task)
	if task.target_page == "":
		task.target_page = target_page
	if task.generation_id <= 0:
		task.generation_id = generation_id
	return task


static func task_key(task: LoadingTask, fallback_page: String = "") -> String:
	var task_page := String(task.target_page)
	if task_page == "":
		task_page = fallback_page
	return "%s|%s" % [String(task.id), task_page]


static func prune_idle_tasks(raw_tasks: Array, target_page: String, generation_id: int, fallback_page: String = "") -> Dictionary:
	var kept: Array = []
	var seen := {}
	var cancelled := 0
	var deduped := 0
	for raw_task in raw_tasks:
		var task := prepare_task(raw_task, fallback_page, generation_id)
		if _task_stale_for_transition(task, target_page, generation_id):
			cancelled += 1
			continue
		var key := task_key(task, fallback_page)
		if seen.has(key):
			deduped += 1
			continue
		seen[key] = true
		kept.append(task)
	return {
		"tasks": kept,
		"cancelled": cancelled,
		"deduped": deduped,
	}


static func queue_deferred_idle_tasks(existing_tasks: Array, incoming_tasks: Array, target_page: String, generation_id: int, fallback_page: String = "") -> Dictionary:
	var kept: Array = []
	var seen := {}
	var cancelled := 0
	var deduped := 0
	var added := 0
	for raw_existing in existing_tasks:
		var existing := prepare_task(raw_existing, fallback_page, generation_id)
		if _task_stale_for_transition(existing, target_page, generation_id):
			cancelled += 1
			continue
		var existing_key := task_key(existing, fallback_page)
		if seen.has(existing_key):
			deduped += 1
			continue
		seen[existing_key] = true
		kept.append(existing)
	for raw_task in incoming_tasks:
		var task := prepare_task(raw_task, target_page, generation_id)
		if task.phase != LoadingTask.PHASE_IDLE or not task.idle_optional:
			cancelled += 1
			continue
		if _task_stale_for_transition(task, target_page, generation_id):
			cancelled += 1
			continue
		var key := task_key(task, fallback_page)
		if seen.has(key):
			deduped += 1
			continue
		seen[key] = true
		kept.append(task)
		added += 1
	return {
		"tasks": kept,
		"cancelled": cancelled,
		"deduped": deduped,
		"added": added,
	}


static func _task_stale_for_transition(task: LoadingTask, target_page: String, generation_id: int) -> bool:
	var task_page := String(task.target_page)
	if task_page != "" and target_page != "" and task_page != target_page:
		return true
	var task_generation := int(task.generation_id)
	return task_generation > 0 and generation_id > 0 and task_generation < generation_id
