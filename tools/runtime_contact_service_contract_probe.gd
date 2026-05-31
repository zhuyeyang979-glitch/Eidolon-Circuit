extends SceneTree

const SERVICE_PATH := "res://scripts/services/runtime_contact_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const RuntimeContactServiceScript := preload("res://scripts/services/runtime_contact_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing RuntimeContactService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name RuntimeContactService",
		"collider_uses_torso_damage",
		"socket_key",
		"pair_key",
		"directed_contact_key",
		"collider_priority",
		"sorted_colliders",
		"damage_coeff",
		"break_coeff",
		"part_stiffness",
		"path_stiffness",
		"break_threshold",
		"damage_type",
		"material_class",
		"contact_source",
		"runtime_pair_intent",
		"gpu_contact_intent",
		"damage_intent",
	]:
		if service_source.find(token) < 0:
			_fail("RuntimeContactService missing token: %s" % token)
			return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "Control.new", "active_units", "all_units", "gpu_collision", "GpuCollisionPipeline", "_spawn_", "_apply_runtime_contact_damage", "take_hit", "queue_free"]:
		if service_source.find(forbidden) >= 0:
			_fail("RuntimeContactService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const RuntimeContactService = preload(\"res://scripts/services/runtime_contact_service.gd\")",
		"var runtime_contact_service: RuntimeContactService",
		"runtime_contact_service = RuntimeContactService.new()",
		"runtime_contact_service.socket_key",
		"runtime_contact_service.sorted_colliders",
		"runtime_contact_service.collider_priority",
		"runtime_contact_service.pair_key",
		"runtime_contact_service.directed_contact_key",
		"runtime_contact_service.damage_coeff",
		"runtime_contact_service.break_coeff",
		"runtime_contact_service.part_stiffness",
		"runtime_contact_service.path_stiffness",
		"runtime_contact_service.break_threshold",
		"runtime_contact_service.damage_type",
		"runtime_contact_service.material_class",
		"runtime_contact_service.runtime_pair_intent",
		"runtime_contact_service.gpu_contact_intent",
		"runtime_contact_service.damage_intent",
		"runtime_contact_service.contact_source",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate runtime contact service token: %s" % token)
			return
	var service = RuntimeContactServiceScript.new()
	var constants := _constants()
	var torso_proxy := {"part_kind": "limb_muscle", "node_index": 2, "torso_unit_index": 4, "damage_proxy": "torso"}
	if not service.collider_uses_torso_damage(torso_proxy):
		_fail("Torso proxy collider should route damage through torso.")
	if service.socket_key(torso_proxy) != "torso:4:proxy":
		_fail("Torso proxy socket key should collapse to torso proxy key.")
	var terminal_melee := {"part_kind": "terminal", "node_index": 3, "torso_unit_index": 0, "terminal_weapon_kind": "melee", "damage_type": "tear", "material_class": "weapon", "independent_damage": true}
	var terminal_ranged := {"part_kind": "terminal", "node_index": 4, "torso_unit_index": 0, "terminal_weapon_kind": "ranged", "material_class": "gun"}
	_assert_eq(service.socket_key(terminal_melee), "terminal:3:0", "terminal socket key")
	_assert_eq(service.pair_key(20, terminal_melee, 10, torso_proxy), "10|torso:4:proxy--20|terminal:3:0", "sorted pair key")
	_assert_eq(service.directed_contact_key(20, terminal_melee, 10, torso_proxy), "20|terminal:3:0->10|torso:4:proxy", "directed pair key")
	if service.collider_priority(terminal_melee) != 0 or service.collider_priority(torso_proxy) != 9:
		_fail("Collider priority should put active terminal before torso proxy.")
	var sorted: Array = service.sorted_colliders([torso_proxy, {"part_kind": "torso"}, terminal_melee])
	if service.collider_priority(sorted[0]) != 0 or service.collider_priority(sorted[sorted.size() - 1]) != 9:
		_fail("sorted_colliders should use collider priority order.")
	if absf(service.damage_coeff(terminal_melee, constants) - 3.2) > 0.001:
		_fail("Melee terminal damage coeff should match constants.")
	if absf(service.damage_coeff(terminal_ranged, constants) - 0.8) > 0.001:
		_fail("Ranged terminal damage coeff should match constants.")
	if absf(service.break_coeff(terminal_melee, constants) - 1.0) > 0.001:
		_fail("Melee terminal break coeff should match constants.")
	if absf(service.part_stiffness(terminal_melee, 1.0, constants) - 1536.0) > 0.001:
		_fail("Melee terminal part stiffness should be base * 2.")
	if absf(service.path_stiffness(terminal_melee, 1.0, constants) - 768.0) > 0.001:
		_fail("Terminal path stiffness should be min terminal/limb/torso.")
	if absf(service.break_threshold(terminal_melee, 1.0, constants) - 3.456) > 0.001:
		_fail("Break threshold should derive from path stiffness and break coeff.")
	_assert_eq(service.damage_type({"damage_type": "laser"}, ["blunt", "pierce", "tear"]), "blunt", "invalid damage type fallback")
	_assert_eq(service.damage_type(terminal_melee, ["blunt", "pierce", "tear"]), "tear", "melee damage type")
	_assert_eq(service.material_class(terminal_ranged), "body", "gun material collision class")
	_assert_eq(service.contact_source(terminal_melee), "active_module_contact", "active source")
	_assert_eq(service.contact_source(torso_proxy), "default_body_contact", "default source")
	var low_intent: Dictionary = service.runtime_pair_intent({
		"normal": Vector2.RIGHT,
		"velocity_a": Vector2(0.1, 0.0),
		"velocity_b": Vector2.ZERO,
		"mass_a": 10.0,
		"mass_b": 10.0,
		"path_stiffness_a": 100.0,
		"path_stiffness_b": 80.0,
		"constants": constants,
	})
	if bool(low_intent.get("should_process", true)):
		_fail("Low-speed CPU contact should not process damage.")
	var pair_intent: Dictionary = service.runtime_pair_intent({
		"normal": Vector2.RIGHT,
		"velocity_a": Vector2(4.0, 0.0),
		"velocity_b": Vector2(-1.0, 0.0),
		"mass_a": 12.0,
		"mass_b": 8.0,
		"path_stiffness_a": 100.0,
		"path_stiffness_b": 70.0,
		"source_a": "active_module_contact",
		"source_b": "default_body_contact",
		"constants": constants,
	})
	if not bool(pair_intent.get("should_process", false)) or absf(float(pair_intent.get("contact_momentum", 0.0)) - 100.0) > 0.001:
		_fail("CPU pair intent should produce closing momentum.")
	if not bool(pair_intent.get("damage_a", false)) or bool(pair_intent.get("damage_b", true)):
		_fail("Active-vs-default contact should suppress reverse default damage.")
	if absf(float(pair_intent.get("response_momentum", 0.0)) - 70.0) > 0.001:
		_fail("Response momentum should be capped by min path stiffness.")
	var gpu_shallow: Dictionary = service.gpu_contact_intent({"normal": Vector2.RIGHT, "penetration": 0.001, "constants": constants})
	if bool(gpu_shallow.get("mark_seen", true)):
		_fail("Shallow GPU contact should not mark pair seen.")
	var gpu_intent: Dictionary = service.gpu_contact_intent({
		"normal": Vector2.RIGHT,
		"penetration": 0.01,
		"raw_contact_momentum": 50.0,
		"usable_contact_momentum": 24.0,
		"relative_normal_velocity": 3.0,
		"owner_a_id": 1,
		"owner_b_id": 2,
		"source_a": "default_body_contact",
		"source_b": "active_module_contact",
		"velocity_delta_a": Vector2.LEFT,
		"velocity_delta_b": Vector2.RIGHT,
		"constants": constants,
	})
	if not bool(gpu_intent.get("should_process", false)) or not bool(gpu_intent.get("damage_b", false)) or bool(gpu_intent.get("damage_a", true)):
		_fail("GPU intent should process and keep active side damage only.")
	if not bool(gpu_intent.get("apply_velocity_delta", false)):
		_fail("GPU intent should preserve velocity response decision.")
	var blocked_damage: Dictionary = service.damage_intent({
		"attacker_id": 1,
		"target_id": 2,
		"attacker_collider": terminal_melee,
		"target_collider": {"part_kind": "torso", "part_index": 0},
		"normal": Vector2.RIGHT,
		"contact_momentum": 5.0,
		"attacker_path_stiffness": 100.0,
		"target_path_stiffness": 100.0,
		"damage_coeff": 1.0,
		"contact_damage_scale": 0.09,
		"break_threshold": 5.0,
		"damage_type": "tear",
		"material_class": "weapon",
		"vulnerability_multiplier": 1.0,
	})
	if not bool(blocked_damage.get("threshold_blocked", false)):
		_fail("Damage intent should expose break-threshold block.")
	var event: Dictionary = Dictionary(blocked_damage.get("event", {}))
	if String(event.get("contact_pair_key", "")) != "1|terminal:3:0->2|torso:0:-1":
		_fail("Damage event should include directed contact key: %s" % String(event.get("contact_pair_key", "")))
	print("RUNTIME_CONTACT_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _constants() -> Dictionary:
	return {
		"contact_damage_scale": 0.09,
		"break_stiffness_scale": 0.0045,
		"part_stiffness_base_momentum": 768.0,
		"part_damage_coeff_torso": 1.0,
		"part_damage_coeff_limb": 1.8,
		"part_damage_coeff_terminal_melee": 3.2,
		"part_damage_coeff_terminal_ranged": 0.8,
		"part_damage_coeff_barrier": 1.0,
		"part_break_coeff_torso": 0.5,
		"part_break_coeff_limb": 0.5,
		"part_break_coeff_terminal_melee": 1.0,
		"part_break_coeff_terminal_ranged": 0.5,
		"part_break_coeff_barrier": 0.5,
		"passive_contact_min_speed": 0.24,
		"runtime_contact_required_overlap": 0.003,
	}


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])
