extends RefCounted
class_name LoadingTask

const PHASE_STARTUP := "startup"
const PHASE_PAGE := "page"
const PHASE_FIRST_INTERACTION := "first_interaction"
const PHASE_IDLE := "idle"

var id := ""
var label := ""
var weight := 1.0
var phase := PHASE_PAGE
var blocking := true
var idle_optional := false
var callable := Callable()

static func _script():
	return load("res://scripts/services/loading_task.gd")


static func create(task_id: String, task_label: String, task_weight: float, task_callable: Callable, task_phase: String = PHASE_PAGE, task_blocking: bool = true, task_idle_optional: bool = false):
	var task = _script().new()
	task.id = task_id
	task.label = task_label
	task.weight = task_weight
	task.callable = task_callable
	task.phase = normalized_phase(task_phase)
	task.blocking = task_blocking
	task.idle_optional = task_idle_optional
	return task


static func from_legacy(value: Variant):
	if value is RefCounted and value.get_script() == _script():
		return value
	if not (value is Dictionary):
		return create("invalid", "Loading", 1.0, Callable(), PHASE_PAGE, true, false)
	var data: Dictionary = value
	var phase := String(data.get("phase", ""))
	if phase == "":
		phase = PHASE_IDLE if bool(data.get("idle_optional", false)) else (PHASE_FIRST_INTERACTION if bool(data.get("first_interaction_critical", true)) and not bool(data.get("essential", true)) else PHASE_PAGE)
	var blocking := bool(data.get("blocking", data.get("essential", not bool(data.get("idle_optional", false)))))
	return create(
		String(data.get("id", "task")),
		String(data.get("label", "Loading")),
		float(data.get("weight", 1.0)),
		data.get("callable", Callable()),
		phase,
		blocking,
		bool(data.get("idle_optional", false))
	)


static func normalized_phase(raw_phase: String) -> String:
	match raw_phase:
		PHASE_STARTUP, PHASE_PAGE, PHASE_FIRST_INTERACTION, PHASE_IDLE:
			return raw_phase
	return PHASE_PAGE


func first_interaction_critical() -> bool:
	return blocking or phase == PHASE_FIRST_INTERACTION


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"label": label,
		"weight": weight,
		"phase": phase,
		"blocking": blocking,
		"idle_optional": idle_optional,
		"callable": callable,
		"essential": blocking,
		"first_interaction_critical": first_interaction_critical(),
	}
