extends RefCounted
class_name LoadingController

const LoadingTask = preload("res://scripts/services/loading_task.gd")

const DEFAULT_BUDGET_USEC := 6000
const DEFAULT_MAX_DURATION_SEC := 10.0
const DEFAULT_MIN_VISIBLE_SEC := 0.0

var state_store
var dirty_graph
var profiler
var target_state := ""
var reason := ""
var active := false
var tasks: Array = []
var completed_weight := 0.0
var total_weight := 0.0
var current_label := ""
var started_usec := 0
var finished_usec := 0
var tick_count := 0
var completed_task_count := 0
var overshoot_count := 0
var task_time_usec := {}
var max_duration_sec := DEFAULT_MAX_DURATION_SEC
var min_visible_sec := DEFAULT_MIN_VISIBLE_SEC
var elapsed_sec := 0.0
var deferred_tasks: Array = []
var forced_finish_count := 0
var first_interaction_critical_pending_count := 0


func bind(store, graph, hot_profiler) -> void:
	state_store = store
	dirty_graph = graph
	profiler = hot_profiler


func begin(next_target_state: String, next_reason: String = "", next_max_duration_sec: float = DEFAULT_MAX_DURATION_SEC, next_min_visible_sec: float = DEFAULT_MIN_VISIBLE_SEC) -> void:
	target_state = next_target_state
	reason = next_reason
	active = true
	tasks.clear()
	deferred_tasks.clear()
	completed_weight = 0.0
	total_weight = 0.0
	current_label = ""
	started_usec = Time.get_ticks_usec()
	finished_usec = 0
	max_duration_sec = maxf(0.0, next_max_duration_sec)
	min_visible_sec = maxf(0.0, next_min_visible_sec)
	elapsed_sec = 0.0
	tick_count = 0
	completed_task_count = 0
	overshoot_count = 0
	forced_finish_count = 0
	first_interaction_critical_pending_count = 0
	task_time_usec.clear()
	if state_store != null:
		state_store.mutate("global", "loading:%s" % reason, 1)
	if dirty_graph != null:
		dirty_graph.mark("global", 1, "loading:%s" % reason)
	if profiler != null:
		profiler.count("loading.begin")


func add_task(id: String, label: String, weight: float, task_callable: Callable, essential: bool = true, first_interaction_critical: bool = true, idle_optional: bool = false) -> void:
	var phase := LoadingTask.PHASE_IDLE if idle_optional else (LoadingTask.PHASE_FIRST_INTERACTION if first_interaction_critical and not essential else LoadingTask.PHASE_PAGE)
	add_loading_task(LoadingTask.create(id, label, weight, task_callable, phase, essential, idle_optional))


func add_loading_task(raw_task: Variant) -> void:
	var normalized = LoadingTask.from_legacy(raw_task)
	var safe_weight := maxf(0.01, normalized.weight)
	tasks.append({
		"id": normalized.id,
		"label": normalized.label,
		"weight": safe_weight,
		"callable": normalized.callable,
		"essential": normalized.blocking,
		"first_interaction_critical": normalized.first_interaction_critical(),
		"idle_optional": normalized.idle_optional,
		"phase": normalized.phase,
		"blocking": normalized.blocking,
	})
	total_weight += safe_weight


func tick(budget_usec: int = DEFAULT_BUDGET_USEC, delta: float = 0.0) -> bool:
	if not active:
		return true
	tick_count += 1
	elapsed_sec += maxf(0.0, delta)
	if delta <= 0.0 and started_usec > 0:
		elapsed_sec = maxf(elapsed_sec, float(Time.get_ticks_usec() - started_usec) / 1000000.0)
	var started := Time.get_ticks_usec()
	var processed := 0
	while not tasks.is_empty():
		if _budget_expired() and not _blocking_tasks_pending():
			_defer_remaining_tasks()
			break
		var task: Dictionary = tasks[0]
		current_label = String(task.get("label", "Loading"))
		var task_started := Time.get_ticks_usec()
		var done := true
		var task_callable: Callable = task.get("callable", Callable())
		if task_callable.is_valid():
			var result = task_callable.call()
			if result is bool:
				done = bool(result)
		var elapsed := Time.get_ticks_usec() - task_started
		var task_id := String(task.get("id", current_label))
		task_time_usec[task_id] = int(task_time_usec.get(task_id, 0)) + elapsed
		if profiler != null:
			profiler.count("loading.task")
			profiler.record_value("loading.last_task_usec", elapsed)
		if not done:
			break
		completed_weight += float(task.get("weight", 1.0))
		tasks.pop_front()
		completed_task_count += 1
		processed += 1
		if budget_usec > 0 and Time.get_ticks_usec() - started >= budget_usec and processed > 0:
			overshoot_count += 1
			break
	first_interaction_critical_pending_count = _critical_tasks_pending_count()
	if tasks.is_empty() and _min_visible_satisfied():
		_finish()
		return true
	return false


func progress() -> float:
	if total_weight <= 0.0:
		return 1.0 if not active else 0.0
	return clampf(completed_weight / total_weight, 0.0, 1.0)


func pending_count() -> int:
	return tasks.size()


func take_deferred_tasks() -> Array:
	var out := deferred_tasks.duplicate(true)
	deferred_tasks.clear()
	return out


func _finish() -> void:
	active = false
	current_label = ""
	finished_usec = Time.get_ticks_usec()
	if profiler != null:
		profiler.count("loading.finish")
		profiler.record_value("loading.last_total_usec", finished_usec - started_usec)
		profiler.record_value("loading.elapsed_sec", elapsed_sec)


func _budget_expired() -> bool:
	return max_duration_sec > 0.0 and elapsed_sec >= max_duration_sec


func _min_visible_satisfied() -> bool:
	return elapsed_sec >= min_visible_sec


func _blocking_tasks_pending() -> bool:
	for raw_task in tasks:
		if not (raw_task is Dictionary):
			continue
		var task: Dictionary = raw_task
		if bool(task.get("essential", true)) or bool(task.get("first_interaction_critical", true)):
			return true
	return false


func _critical_tasks_pending_count() -> int:
	var count := 0
	for raw_task in tasks:
		if raw_task is Dictionary and bool(Dictionary(raw_task).get("first_interaction_critical", true)):
			count += 1
	return count


func _defer_remaining_tasks() -> void:
	for raw_task in tasks:
		if raw_task is Dictionary:
			deferred_tasks.append(raw_task)
	tasks.clear()
	forced_finish_count += 1
	if profiler != null:
		profiler.count("loading.forced_finish")


func summary_line() -> String:
	return "loading %s %.0f%% tasks:%d done:%d ticks:%d over:%d %s" % [
		target_state,
		progress() * 100.0,
		tasks.size(),
		completed_task_count,
		tick_count,
		overshoot_count,
		current_label,
	]
