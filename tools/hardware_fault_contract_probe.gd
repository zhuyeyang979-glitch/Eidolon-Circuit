extends SceneTree

const SERVICE_PATH := "res://scripts/services/hardware_fault_runtime_service.gd"

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _require_close(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) <= 0.001:
		return
	_fail("%s expected %.3f got %.3f" % [label, expected, actual])


func _init() -> void:
	_require(FileAccess.file_exists(SERVICE_PATH), "Missing HardwareFaultRuntimeService script.")
	if failed:
		quit(1)
		return
	var ServiceScript = load(SERVICE_PATH)
	_require(ServiceScript != null, "Could not load HardwareFaultRuntimeService.")
	if failed:
		quit(1)
		return
	var service = ServiceScript.new()

	_capacity_checks(service)
	_transition_checks(service)
	_action_dependency_checks(service)
	_ordering_checks(service)

	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_CONTRACT_PROBE ok")
	quit(0)


func _capacity_checks(service) -> void:
	_require_close(service.runtime_momentum_capacity({"momentum_capacity": 12.0, "stiffness_momentum": 4.0}, 2.0), 12.0, "Explicit momentum capacity")
	_require_close(service.runtime_momentum_capacity({"embedded_joint_momentum_capacity": 9.0, "stiffness_momentum": 4.0}, 2.0, "embedded_joint"), 9.0, "Embedded joint capacity")
	_require_close(service.runtime_momentum_capacity({"stiffness_momentum": 7.5}, 2.0), 7.5, "Stiffness fallback capacity")
	_require_close(service.runtime_momentum_capacity({}, 0.2), 1.0, "Capacity clamps to minimum one")


func _transition_checks(service) -> void:
	var equality: Dictionary = service.hit_transition({
		"raw_momentum": 10.0,
		"path_stiffness_momentum": 10.0,
		"runtime_momentum_capacity": 10.0,
		"pre_state": "normal",
		"construct_body_id": "body-a",
		"hardware_node_id": 2,
		"primary_core_node_id": 0,
	})
	_require(not bool(equality.get("overloaded", true)), "Equality should not overload: %s" % str(equality))
	_require(String(equality.get("post_state", "")) == "normal", "Equality should remain normal.")
	_require_close(float(equality.get("hardware_capped_momentum", -1.0)), 10.0, "Equality capped momentum")
	_require(String(equality.get("destruction_intent", "")) == "none", "Equality should not create destruction intent.")

	var first_overload: Dictionary = service.hit_transition({
		"raw_momentum": 18.0,
		"path_stiffness_momentum": 14.0,
		"runtime_momentum_capacity": 10.0,
		"pre_state": "normal",
		"construct_body_id": "body-a",
		"hardware_node_id": 2,
		"primary_core_node_id": 0,
	})
	_require(bool(first_overload.get("overloaded", false)), "First overload should be detected.")
	_require(String(first_overload.get("post_state", "")) == "faulted", "First overload should fault hardware: %s" % str(first_overload))
	_require_close(float(first_overload.get("path_capped_momentum", -1.0)), 14.0, "Path cap should apply before hardware cap")
	_require_close(float(first_overload.get("hardware_capped_momentum", -1.0)), 10.0, "Hardware cap should apply to damage momentum")
	_require(String(first_overload.get("destruction_intent", "")) == "none", "First overload should not destroy hardware.")

	var faulted_subcap: Dictionary = service.hit_transition({
		"raw_momentum": 8.0,
		"path_stiffness_momentum": 8.0,
		"runtime_momentum_capacity": 10.0,
		"pre_state": "faulted",
		"construct_body_id": "body-a",
		"hardware_node_id": 2,
		"primary_core_node_id": 0,
	})
	_require(not bool(faulted_subcap.get("overloaded", true)), "Sub-cap hit should not overload while faulted.")
	_require(String(faulted_subcap.get("post_state", "")) == "faulted", "Sub-cap hit should remain faulted.")

	var second_overload: Dictionary = service.hit_transition({
		"raw_momentum": 12.0,
		"path_stiffness_momentum": 12.0,
		"runtime_momentum_capacity": 10.0,
		"pre_state": "faulted",
		"construct_body_id": "body-a",
		"hardware_node_id": 2,
		"primary_core_node_id": 0,
	})
	_require(String(second_overload.get("post_state", "")) == "destroyed", "Second overload should destroy hardware.")
	_require(String(second_overload.get("destruction_intent", "")) == "destroy_hardware", "Non-core destruction should target hardware.")
	_require(int(second_overload.get("transition_sequence", 0)) == 1, "Transition sequence should increment on state change.")

	var core_overload: Dictionary = service.hit_transition({
		"raw_momentum": 12.0,
		"path_stiffness_momentum": 12.0,
		"runtime_momentum_capacity": 10.0,
		"pre_state": "faulted",
		"construct_body_id": "body-a",
		"hardware_node_id": 0,
		"primary_core_node_id": 0,
	})
	_require(String(core_overload.get("destruction_intent", "")) == "destroy_construct_body", "Core destruction should target the construct body.")


func _action_dependency_checks(service) -> void:
	var blocked: Dictionary = service.action_dependency_report(["arm-a"], {
		"arm-a": "faulted",
		"arm-b": "normal",
	})
	_require(not bool(blocked.get("allowed", true)), "Faulted dependency should block action.")
	_require(String(blocked.get("blocked_hardware_id", "")) == "arm-a", "Blocked action should name the first failed dependency.")
	_require(String(blocked.get("blocking_state", "")) == "faulted", "Blocked action should expose the blocking state.")

	var unrelated: Dictionary = service.action_dependency_report(["arm-b"], {
		"arm-a": "faulted",
		"arm-b": "normal",
	})
	_require(bool(unrelated.get("allowed", false)), "Unrelated fault should not block action.")

	var destroyed: Dictionary = service.action_dependency_report(["arm-c"], {"arm-c": "destroyed"})
	_require(not bool(destroyed.get("allowed", true)), "Destroyed dependency should block action.")


func _ordering_checks(service) -> void:
	var ordered: Array = service.ordered_destruction_intents([
		{"construct_body_id": "body-b", "hardware_node_id": 1},
		{"construct_body_id": "body-a", "hardware_node_id": 4},
		{"construct_body_id": "body-a", "hardware_node_id": 2},
	])
	_require(ordered.size() == 3, "Ordered destruction intents should preserve all entries.")
	_require(String(Dictionary(ordered[0]).get("construct_body_id", "")) == "body-a" and int(Dictionary(ordered[0]).get("hardware_node_id", -1)) == 2, "First ordered intent should be body-a node 2: %s" % str(ordered))
	_require(String(Dictionary(ordered[1]).get("construct_body_id", "")) == "body-a" and int(Dictionary(ordered[1]).get("hardware_node_id", -1)) == 4, "Second ordered intent should be body-a node 4: %s" % str(ordered))
	_require(String(Dictionary(ordered[2]).get("construct_body_id", "")) == "body-b", "Third ordered intent should be body-b: %s" % str(ordered))
