extends RefCounted
class_name HardwareFaultRuntimeService

const STATE_NORMAL := "normal"
const STATE_FAULTED := "faulted"
const STATE_DESTROYED := "destroyed"

const TRANSITION_NONE := "none"
const TRANSITION_FAULT := "fault"
const TRANSITION_DESTROY := "destroy"

const DESTRUCTION_NONE := "none"
const DESTRUCTION_HARDWARE := "destroy_hardware"
const DESTRUCTION_CONSTRUCT_BODY := "destroy_construct_body"


func runtime_momentum_capacity(part: Dictionary, fallback_capacity: float = 1.0, hardware_kind: String = "") -> float:
	var explicit_capacity := _positive_float(part.get("momentum_capacity", 0.0))
	if explicit_capacity > 0.0:
		return maxf(1.0, explicit_capacity)
	if hardware_kind == "embedded_joint":
		var embedded_capacity := _positive_float(part.get("embedded_joint_momentum_capacity", 0.0))
		if embedded_capacity > 0.0:
			return maxf(1.0, embedded_capacity)
	var stiffness_capacity := _positive_float(part.get("stiffness_momentum", 0.0))
	if stiffness_capacity > 0.0:
		return maxf(1.0, stiffness_capacity)
	return maxf(1.0, fallback_capacity)


func hit_transition(context: Dictionary) -> Dictionary:
	var raw_momentum := maxf(0.0, _float_value(context.get("raw_momentum", 0.0), 0.0))
	var path_limit := _positive_float(context.get("path_stiffness_momentum", context.get("path_capped_momentum", raw_momentum)))
	if path_limit <= 0.0:
		path_limit = raw_momentum
	var runtime_capacity := maxf(1.0, _float_value(context.get("runtime_momentum_capacity", 1.0), 1.0))
	var path_capped_momentum := minf(raw_momentum, path_limit)
	var hardware_capped_momentum := minf(path_capped_momentum, runtime_capacity)
	var pre_state := normalized_state(String(context.get("pre_state", STATE_NORMAL)))
	var overloaded := pre_state != STATE_DESTROYED and path_capped_momentum > runtime_capacity
	var post_state := pre_state
	var transition := TRANSITION_NONE
	var destruction_intent := DESTRUCTION_NONE
	if overloaded:
		match pre_state:
			STATE_NORMAL:
				post_state = STATE_FAULTED
				transition = TRANSITION_FAULT
			STATE_FAULTED:
				post_state = STATE_DESTROYED
				transition = TRANSITION_DESTROY
				destruction_intent = DESTRUCTION_CONSTRUCT_BODY if _is_primary_core(context) else DESTRUCTION_HARDWARE
	var transitioned := transition != TRANSITION_NONE
	var sequence := int(context.get("transition_sequence", 0))
	if transitioned:
		sequence += 1
	return {
		"raw_momentum": raw_momentum,
		"path_capped_momentum": path_capped_momentum,
		"hardware_capped_momentum": hardware_capped_momentum,
		"runtime_momentum_capacity": runtime_capacity,
		"overloaded": overloaded,
		"pre_state": pre_state,
		"post_state": post_state,
		"transition": transition,
		"transitioned": transitioned,
		"transition_sequence": sequence,
		"destruction_intent": destruction_intent,
		"construct_body_id": str(context.get("construct_body_id", "")),
		"hardware_node_id": context.get("hardware_node_id", ""),
		"primary_core_node_id": context.get("primary_core_node_id", ""),
	}


func action_dependency_report(required_hardware_ids: Array, state_by_hardware_id: Dictionary) -> Dictionary:
	for raw_id in required_hardware_ids:
		var hardware_id := str(raw_id)
		var state := normalized_state(str(state_by_hardware_id.get(raw_id, state_by_hardware_id.get(hardware_id, STATE_NORMAL))))
		if state == STATE_FAULTED or state == STATE_DESTROYED:
			return {
				"allowed": false,
				"blocked": true,
				"blocked_hardware_id": hardware_id,
				"blocking_state": state,
			}
	return {
		"allowed": true,
		"blocked": false,
		"blocked_hardware_id": "",
		"blocking_state": STATE_NORMAL,
	}


func ordered_destruction_intents(raw_intents: Array) -> Array:
	var intents: Array = []
	for raw_intent in raw_intents:
		if raw_intent is Dictionary:
			intents.append(Dictionary(raw_intent).duplicate(true))
	intents.sort_custom(Callable(self, "_sort_destruction_intent_before"))
	return intents


func normalized_state(raw_state: String) -> String:
	match raw_state.strip_edges().to_lower():
		STATE_FAULTED:
			return STATE_FAULTED
		STATE_DESTROYED:
			return STATE_DESTROYED
	return STATE_NORMAL


func _is_primary_core(context: Dictionary) -> bool:
	if context.has("is_primary_core"):
		return bool(context.get("is_primary_core", false))
	if not context.has("hardware_node_id") or not context.has("primary_core_node_id"):
		return false
	return str(context.get("hardware_node_id", "")) == str(context.get("primary_core_node_id", ""))


func _positive_float(raw_value) -> float:
	var value := _float_value(raw_value, 0.0)
	return value if value > 0.0 else 0.0


func _float_value(raw_value, fallback: float = 0.0) -> float:
	if raw_value is int or raw_value is float:
		return float(raw_value)
	var text := str(raw_value).strip_edges()
	if text.is_valid_float():
		return float(text)
	return fallback


func _sort_destruction_intent_before(a: Dictionary, b: Dictionary) -> bool:
	var a_body := str(a.get("construct_body_id", ""))
	var b_body := str(b.get("construct_body_id", ""))
	if a_body != b_body:
		return a_body < b_body
	return _hardware_node_sort_key(a.get("hardware_node_id", "")) < _hardware_node_sort_key(b.get("hardware_node_id", ""))


func _hardware_node_sort_key(raw_value) -> int:
	if raw_value is int or raw_value is float:
		return int(raw_value)
	var text := str(raw_value).strip_edges()
	if text.is_valid_int():
		return int(text)
	return hash(text)
