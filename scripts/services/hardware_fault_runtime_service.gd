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


func contact_transition_batch(initial_state_table: Dictionary, raw_contacts: Array) -> Dictionary:
	var state_table := _duplicate_state_table(initial_state_table)
	var contacts := _ordered_contacts(raw_contacts)
	var transition_events: Array = []
	var destruction_intents: Array = []
	for raw_contact in contacts:
		if not (raw_contact is Dictionary):
			continue
		var contact: Dictionary = raw_contact
		var body_id := str(contact.get("target_construct_body_id", contact.get("construct_body_id", "")))
		var hardware_id = contact.get("target_hardware_node_id", contact.get("hardware_node_id", ""))
		var body_state := _body_state_for_write(state_table, body_id)
		var hardware_state := _hardware_state_for_write(body_state, hardware_id)
		var context := contact.duplicate(true)
		context["construct_body_id"] = body_id
		context["hardware_node_id"] = hardware_id
		context["runtime_momentum_capacity"] = maxf(1.0, _float_value(context.get("runtime_momentum_capacity", hardware_state.get("runtime_momentum_capacity", 1.0)), 1.0))
		context["pre_state"] = normalized_state(str(hardware_state.get("state", STATE_NORMAL)))
		context["transition_sequence"] = int(hardware_state.get("transition_sequence", 0))
		context["primary_core_node_id"] = context.get("primary_core_node_id", hardware_state.get("primary_core_node_id", ""))
		var transition := hit_transition(context)
		hardware_state["state"] = String(transition.get("post_state", STATE_NORMAL))
		hardware_state["runtime_momentum_capacity"] = float(transition.get("runtime_momentum_capacity", context["runtime_momentum_capacity"]))
		hardware_state["transition_sequence"] = int(transition.get("transition_sequence", context["transition_sequence"]))
		if str(context.get("primary_core_node_id", "")).strip_edges() != "":
			hardware_state["primary_core_node_id"] = context.get("primary_core_node_id", "")
		body_state[hardware_id] = hardware_state
		state_table[body_id] = body_state
		if bool(transition.get("transitioned", false)):
			var event := _transition_event_from_contact(contact, transition, body_id, hardware_id)
			transition_events.append(event)
			var destruction_intent := String(transition.get("destruction_intent", DESTRUCTION_NONE))
			if destruction_intent != DESTRUCTION_NONE:
				destruction_intents.append({
					"destruction_intent": destruction_intent,
					"construct_body_id": body_id,
					"hardware_node_id": hardware_id,
					"simulation_tick": int(contact.get("simulation_tick", 0)),
					"contact_sequence": int(contact.get("contact_sequence", 0)),
				})
	return {
		"state_table": state_table,
		"transition_events": transition_events,
		"destruction_intents": ordered_destruction_intents(destruction_intents),
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


func _ordered_contacts(raw_contacts: Array) -> Array:
	var contacts: Array = []
	for raw_contact in raw_contacts:
		if raw_contact is Dictionary:
			contacts.append(Dictionary(raw_contact).duplicate(true))
	contacts.sort_custom(Callable(self, "_sort_contact_before"))
	return contacts


func _sort_contact_before(a: Dictionary, b: Dictionary) -> bool:
	var a_tick := int(a.get("simulation_tick", 0))
	var b_tick := int(b.get("simulation_tick", 0))
	if a_tick != b_tick:
		return a_tick < b_tick
	var a_sequence := int(a.get("contact_sequence", 0))
	var b_sequence := int(b.get("contact_sequence", 0))
	if a_sequence != b_sequence:
		return a_sequence < b_sequence
	var a_body := str(a.get("target_construct_body_id", a.get("construct_body_id", "")))
	var b_body := str(b.get("target_construct_body_id", b.get("construct_body_id", "")))
	if a_body != b_body:
		return a_body < b_body
	return _hardware_node_sort_key(a.get("target_hardware_node_id", a.get("hardware_node_id", ""))) < _hardware_node_sort_key(b.get("target_hardware_node_id", b.get("hardware_node_id", "")))


func _duplicate_state_table(initial_state_table: Dictionary) -> Dictionary:
	var state_table := {}
	for raw_body_id in initial_state_table.keys():
		var body_id := str(raw_body_id)
		var raw_body = initial_state_table[raw_body_id]
		var body_state := {}
		if raw_body is Dictionary:
			for hardware_id in Dictionary(raw_body).keys():
				var raw_hardware = Dictionary(raw_body)[hardware_id]
				body_state[hardware_id] = Dictionary(raw_hardware).duplicate(true) if raw_hardware is Dictionary else {}
		state_table[body_id] = body_state
	return state_table


func _body_state_for_write(state_table: Dictionary, body_id: String) -> Dictionary:
	var raw_body = state_table.get(body_id, {})
	return Dictionary(raw_body).duplicate(true) if raw_body is Dictionary else {}


func _hardware_state_for_write(body_state: Dictionary, hardware_id) -> Dictionary:
	var raw_state = body_state.get(hardware_id, body_state.get(str(hardware_id), {}))
	var hardware_state := Dictionary(raw_state).duplicate(true) if raw_state is Dictionary else {}
	if not hardware_state.has("state"):
		hardware_state["state"] = STATE_NORMAL
	if not hardware_state.has("runtime_momentum_capacity"):
		hardware_state["runtime_momentum_capacity"] = 1.0
	if not hardware_state.has("transition_sequence"):
		hardware_state["transition_sequence"] = 0
	return hardware_state


func _transition_event_from_contact(contact: Dictionary, transition: Dictionary, body_id: String, hardware_id) -> Dictionary:
	return {
		"simulation_tick": int(contact.get("simulation_tick", 0)),
		"contact_sequence": int(contact.get("contact_sequence", 0)),
		"attacker_actor_id": str(contact.get("attacker_actor_id", "")),
		"target_construct_body_id": body_id,
		"target_hardware_node_id": str(hardware_id),
		"raw_momentum": float(transition.get("raw_momentum", 0.0)),
		"path_capped_momentum": float(transition.get("path_capped_momentum", 0.0)),
		"hardware_capped_momentum": float(transition.get("hardware_capped_momentum", 0.0)),
		"runtime_momentum_capacity": float(transition.get("runtime_momentum_capacity", 1.0)),
		"pre_state": String(transition.get("pre_state", STATE_NORMAL)),
		"post_state": String(transition.get("post_state", STATE_NORMAL)),
		"transition": String(transition.get("transition", TRANSITION_NONE)),
		"transition_sequence": int(transition.get("transition_sequence", 0)),
		"destruction_intent": String(transition.get("destruction_intent", DESTRUCTION_NONE)),
	}
