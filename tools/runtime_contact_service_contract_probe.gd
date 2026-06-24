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
		"velocity_response_intent",
		"runtime_node_array_has",
		"runtime_action_phase",
		"runtime_recovery_capable",
		"passive_contact_scrape_factor",
		"meta_safe_part_index",
		"passive_contact_damage_key",
		"unit_contact_radius",
		"unit_effective_mass",
		"unit_thruster_power",
		"unit_knockback_resist",
		"unit_impulse_motion_mult",
		"unit_melee_stability_threshold",
		"unit_posture_anchor",
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
		"func _runtime_contact_service() -> RuntimeContactService",
		"_runtime_contact_service().socket_key(collider)",
		"_runtime_contact_service().sorted_colliders(colliders)",
		"_runtime_contact_service().collider_priority(raw_collider)",
		"_runtime_contact_service().pair_key(aid, collider_a, bid, collider_b)",
		"_runtime_contact_service().directed_contact_key(aid, collider_a, bid, collider_b)",
		"_runtime_contact_service().collider_uses_torso_damage(collider)",
		"_runtime_contact_service().damage_coeff(collider, _runtime_contact_constants())",
		"_runtime_contact_service().break_coeff(collider, _runtime_contact_constants())",
		"_runtime_contact_service().part_stiffness(collider, _collider_stiffness_size_multiplier(collider, unit), _runtime_contact_constants())",
		"_runtime_contact_service().path_stiffness(collider, _collider_stiffness_size_multiplier(collider, unit), _runtime_contact_constants())",
		"_runtime_contact_service().break_threshold(collider, _collider_stiffness_size_multiplier(collider, unit), _runtime_contact_constants())",
		"_runtime_contact_service().damage_type(collider, MELEE_DAMAGE_TYPES)",
		"_runtime_contact_service().material_class(collider)",
		"_runtime_contact_service().runtime_pair_intent",
		"_runtime_contact_service().gpu_contact_intent",
		"_runtime_contact_service().damage_intent",
		"_runtime_contact_service().velocity_response_intent",
		"_runtime_contact_service().runtime_recovery_capable",
		"_runtime_contact_service().runtime_action_phase",
		"_runtime_contact_service().passive_contact_scrape_factor",
		"_runtime_contact_service().passive_contact_damage_key",
		"_runtime_contact_service().unit_contact_radius",
		"_runtime_contact_service().unit_effective_mass",
		"_runtime_contact_service().unit_thruster_power",
		"_runtime_contact_service().unit_knockback_resist",
		"_runtime_contact_service().unit_impulse_motion_mult",
		"_runtime_contact_service().unit_melee_stability_threshold",
		"_runtime_contact_service().unit_posture_anchor",
		"\"melee_stability_threshold_floor\": MELEE_STABILITY_THRESHOLD_FLOOR",
		"_runtime_contact_service().contact_source(collider)",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate runtime contact service token: %s" % token)
			return
	for stale_scalar_parse in [
		"if runtime_contact_service != null:\n\t\treturn runtime_contact_service.socket_key(collider)",
		"var sorted := colliders.duplicate()\n\tsorted.sort_custom(Callable(self, \"_runtime_contact_collider_sort\"))",
		"if not (raw_collider is Dictionary):\n\t\treturn 999",
		"var a_socket := _runtime_contact_socket_key(collider_a)\n\tvar b_socket := _runtime_contact_socket_key(collider_b)",
		"if runtime_contact_service != null:\n\t\treturn runtime_contact_service.collider_uses_torso_damage(collider)",
		"if runtime_contact_service != null:\n\t\treturn runtime_contact_service.damage_coeff(collider, _runtime_contact_constants())",
		"if _runtime_collider_uses_torso_damage(collider):\n\t\treturn PART_DAMAGE_COEFF_TORSO",
		"if runtime_contact_service != null:\n\t\treturn runtime_contact_service.break_coeff(collider, _runtime_contact_constants())",
		"if runtime_contact_service != null:\n\t\treturn runtime_contact_service.part_stiffness(collider, _collider_stiffness_size_multiplier(collider, unit), _runtime_contact_constants())",
		"if runtime_contact_service != null:\n\t\treturn runtime_contact_service.path_stiffness(collider, _collider_stiffness_size_multiplier(collider, unit), _runtime_contact_constants())",
		"if runtime_contact_service != null:\n\t\treturn runtime_contact_service.break_threshold(collider, _collider_stiffness_size_multiplier(collider, unit), _runtime_contact_constants())",
		"if runtime_contact_service != null:\n\t\treturn runtime_contact_service.damage_type(collider, MELEE_DAMAGE_TYPES)",
		"if runtime_contact_service != null:\n\t\treturn runtime_contact_service.material_class(collider)",
		"if runtime_contact_service != null:\n\t\treturn runtime_contact_service.contact_source(collider)",
		"}) if runtime_contact_service != null else {}",
		"if runtime_contact_service == null:\n\t\tif penetration <= RUNTIME_CONTACT_REQUIRED_OVERLAP",
		"if runtime_contact_service == null:\n\t\tvar fallback_usable_momentum",
		"if runtime_contact_service == null:\n\t\tvar fallback_closing_speed",
		"a.velocity -= direction * (contact_momentum / mass_a)",
		"b.velocity += direction * (contact_momentum / mass_b)",
		"func _runtime_node_array_has_for_gpu",
		"var duration := maxf(0.001, float(action.get(\"duration\", 0.62)))\n\t\tvar phase := clampf(1.0 - float(action.get(\"timer\", 0.0)) / duration, 0.0, 1.0)",
		"match String(collider.get(\"part_kind\", \"\")):\n\t\t\"terminal\":\n\t\t\treturn PASSIVE_CONTACT_SCRAPE_MULT",
		"func _meta_safe_part_index",
		"return \"passive_contact_%d_%d_%s_%s_%s_%s_%s\"",
		"var body_radius := maxf(0.04, float(unit.stats.get(\"radius\", 0.22)))",
		"sqrt(body_radius * body_length) * 0.18",
		"return maxf(1.0, float(unit.stats.get(\"mass\", 1.0)))",
		"var mass := maxf(1.0, float(unit.stats.get(\"mass\", 1.0)))\n\treturn maxf(0.0, float(unit.stats.get(\"boost_momentum\", 0.0))) / mass",
		"return clampf(float(unit.stats.get(\"knockback_resist\", 0.0)), 0.0, 0.68)",
		"return clampf(1.0 - _unit_knockback_resist(unit) * 0.72, 0.48, 1.12)",
		"return maxf(MELEE_STABILITY_THRESHOLD_FLOOR, float(unit.stats.get(\"melee_stability_threshold\", MELEE_STABILITY_THRESHOLD_FLOOR)))",
		"var stabilization := clampf(float(unit.stats.get(\"recoil_stabilization\", unit.stats.get(\"attitude_control\", 0.85))), 0.0, 2.6)",
		"var thruster_anchor := thruster / maxf(0.001, thruster + opposing_mass * 0.36 + mass * 0.04 + 6.0)",
	]:
		if main_source.find(stale_scalar_parse) >= 0:
			_fail("main.gd should not keep duplicate runtime contact scalar fallback: %s" % stale_scalar_parse)
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
	_assert_eq(service.damage_type({"damage_type": "slash"}, ["blunt", "pierce", "tear"]), "tear", "slash alias")
	_assert_eq(service.damage_type({"damage_type": "stab"}, ["blunt", "pierce", "tear"]), "pierce", "stab alias")
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
	var equal_break_damage: Dictionary = service.damage_intent({
		"attacker_id": 1,
		"target_id": 2,
		"attacker_collider": terminal_melee,
		"target_collider": {"part_kind": "torso", "part_index": 0},
		"normal": Vector2.RIGHT,
		"contact_momentum": 5.0,
		"attacker_path_stiffness": 100.0,
		"target_path_stiffness": 100.0,
		"damage_coeff": 1.0,
		"contact_damage_scale": 1.0,
		"break_threshold": 5.0,
		"damage_type": "tear",
		"material_class": "weapon",
		"vulnerability_multiplier": 1.0,
	})
	if not bool(equal_break_damage.get("threshold_blocked", false)):
		_fail("Damage intent should block when damage equals break value.")
	var equal_event: Dictionary = Dictionary(equal_break_damage.get("event", {}))
	if absf(float(equal_event.get("break_value", 0.0)) - 5.0) > 0.001 or absf(float(equal_event.get("damage_coefficient", 0.0)) - 1.0) > 0.001:
		_fail("Damage event should expose momentum formula fields: %s" % str(equal_event))
	for field in ["momentum", "raw_momentum", "damage_coefficient", "adjustment_coefficient", "break_value", "effective_break_value", "knock_momentum"]:
		if not equal_event.has(field):
			_fail("Runtime contact damage event missing telemetry field %s: %s" % [field, str(equal_event)])
	var velocity_response: Dictionary = service.velocity_response_intent({
		"normal": Vector2(2.0, 0.0),
		"contact_momentum": 30.0,
		"mass_a": 10.0,
		"mass_b": 5.0,
	})
	if not bool(velocity_response.get("should_apply", false)):
		_fail("Velocity response should apply for positive momentum and valid normal.")
	_assert_vec_close(velocity_response.get("velocity_delta_a", Vector2.ZERO), Vector2(-3.0, 0.0), "velocity response delta A")
	_assert_vec_close(velocity_response.get("velocity_delta_b", Vector2.ZERO), Vector2(6.0, 0.0), "velocity response delta B")
	var anchored_response: Dictionary = service.velocity_response_intent({
		"normal": Vector2.RIGHT,
		"contact_momentum": 30.0,
		"mass_a": 10.0,
		"mass_b": 5.0,
		"anchored_a": true,
	})
	_assert_vec_close(anchored_response.get("velocity_delta_a", Vector2.ONE), Vector2.ZERO, "anchored velocity response delta A")
	_assert_vec_close(anchored_response.get("velocity_delta_b", Vector2.ZERO), Vector2(6.0, 0.0), "anchored velocity response delta B")
	var invalid_response: Dictionary = service.velocity_response_intent({"normal": Vector2.ZERO, "contact_momentum": 30.0})
	if bool(invalid_response.get("should_apply", true)):
		_fail("Velocity response should reject invalid normal.")
	var action_phase_actions := [
		{"target_nodes": [1, "4"], "duration": 2.0, "timer": 1.0, "startup_ratio": 0.6},
		{"target_nodes": [8], "duration": 1.0, "timer": 0.2, "startup_ratio": 0.4},
	]
	if not service.runtime_node_array_has(["1", 4], 4):
		_fail("Runtime node array helper should match numeric string node ids.")
	if absf(service.runtime_action_phase(action_phase_actions, 4) - 0.5) > 0.001:
		_fail("GPU action phase should derive phase from the first action targeting the node.")
	if not service.runtime_recovery_capable(action_phase_actions, 4):
		_fail("GPU recovery should be capable during startup phase.")
	if service.runtime_recovery_capable(action_phase_actions, 8):
		_fail("GPU recovery should be false after startup ratio.")
	if absf(service.runtime_action_phase(action_phase_actions, 42) - 1.0) > 0.001:
		_fail("GPU action phase should fall back to 1.0 when no action targets the node.")
	if absf(service.passive_contact_scrape_factor({"part_kind": "terminal"}, constants) - 0.42) > 0.001:
		_fail("Terminal scrape factor should use the base passive scrape multiplier.")
	if absf(service.passive_contact_scrape_factor({"part_kind": "limb_muscle", "contact_damage_mult": 0.10}, constants) - 0.105) > 0.001:
		_fail("Limb scrape factor should apply the minimum contact damage multiplier.")
	if absf(service.passive_contact_scrape_factor({"part_kind": "joint"}, constants) - 0.0756) > 0.001:
		_fail("Joint scrape factor should use the joint multiplier.")
	if absf(service.passive_contact_scrape_factor({"part_kind": "unknown"}, constants) - 0.1176) > 0.001:
		_fail("Unknown scrape factor should use the fallback multiplier.")
	_assert_eq(service.meta_safe_part_index(-3), "m3", "negative meta-safe part index")
	_assert_eq(service.meta_safe_part_index(4), "4", "positive meta-safe part index")
	var passive_key: String = service.passive_contact_damage_key(11, {"part_index": -2, "part_kind": "terminal"}, 22, {"part_index": 5, "part_kind": "torso"}, "normal")
	_assert_eq(passive_key, "passive_contact_11_22_m2_terminal_5_torso_normal", "passive contact damage key")
	if absf(service.unit_contact_radius({"radius": 0.25, "length": 1.0, "group_count": 4}, constants) - 0.433) > 0.001:
		_fail("Unit contact radius should match body radius/length/limb formula.")
	if absf(service.unit_contact_radius({}, constants) - 0.402237) > 0.001:
		_fail("Unit contact radius should use existing default stats.")
	if absf(service.unit_contact_radius({"radius": 0.0, "length": 0.0, "group_count": 0}, constants) - 0.18) > 0.001:
		_fail("Unit contact radius should clamp very small bodies to the minimum.")
	if absf(service.unit_effective_mass({"mass": 3.5}) - 3.5) > 0.001:
		_fail("Unit effective mass should read positive mass stat.")
	if absf(service.unit_effective_mass({"mass": 0.2}) - 1.0) > 0.001:
		_fail("Unit effective mass should clamp low mass to 1.0.")
	if absf(service.unit_effective_mass({}) - 1.0) > 0.001:
		_fail("Unit effective mass should default to 1.0.")
	if absf(service.unit_thruster_power({"mass": 10.0, "boost_momentum": 25.0}) - 2.5) > 0.001:
		_fail("Unit thruster power should divide positive boost momentum by effective mass.")
	if absf(service.unit_thruster_power({"mass": 0.2, "boost_momentum": 3.0}) - 3.0) > 0.001:
		_fail("Unit thruster power should use clamped effective mass.")
	if absf(service.unit_thruster_power({"mass": 2.0, "boost_momentum": -4.0})) > 0.001:
		_fail("Unit thruster power should clamp negative boost momentum to zero.")
	if absf(service.unit_thruster_power({})) > 0.001:
		_fail("Unit thruster power should default to zero without boost momentum.")
	if absf(service.unit_knockback_resist({"knockback_resist": 0.42}) - 0.42) > 0.001:
		_fail("Unit knockback resist should read positive stat values.")
	if absf(service.unit_knockback_resist({"knockback_resist": -0.2})) > 0.001:
		_fail("Unit knockback resist should clamp negative values to zero.")
	if absf(service.unit_knockback_resist({"knockback_resist": 2.0}) - 0.68) > 0.001:
		_fail("Unit knockback resist should clamp high values to the existing cap.")
	if absf(service.unit_knockback_resist({})) > 0.001:
		_fail("Unit knockback resist should default to zero.")
	if absf(service.unit_impulse_motion_mult({}) - 1.0) > 0.001:
		_fail("Unit impulse motion multiplier should default to neutral.")
	if absf(service.unit_impulse_motion_mult({"knockback_resist": 0.42}) - 0.6976) > 0.001:
		_fail("Unit impulse motion multiplier should apply the existing resist slope.")
	if absf(service.unit_impulse_motion_mult({"knockback_resist": 2.0}) - 0.5104) > 0.001:
		_fail("Unit impulse motion multiplier should use clamped knockback resist.")
	if absf(service.unit_melee_stability_threshold({"melee_stability_threshold": 64.0}, constants) - 64.0) > 0.001:
		_fail("Unit melee stability threshold should read positive stat values.")
	if absf(service.unit_melee_stability_threshold({"melee_stability_threshold": 10.0}, constants) - 28.0) > 0.001:
		_fail("Unit melee stability threshold should clamp low values to the floor.")
	if absf(service.unit_melee_stability_threshold({}, constants) - 28.0) > 0.001:
		_fail("Unit melee stability threshold should default to the floor.")
	if absf(service.unit_melee_stability_threshold({"melee_stability_threshold": 10.0}, {"melee_stability_threshold_floor": 12.0}) - 12.0) > 0.001:
		_fail("Unit melee stability threshold should use provided floor constant.")
	if absf(service.unit_posture_anchor({}, 0.0) - 0.012) > 0.001:
		_fail("Unit posture anchor should use the existing default stabilization.")
	if absf(service.unit_posture_anchor({"mass": 10.0, "boost_momentum": 25.0, "knockback_resist": 0.2, "recoil_stabilization": 1.2}, 20.0) - 0.361118) > 0.001:
		_fail("Unit posture anchor should combine thruster and control anchors.")
	if absf(service.unit_posture_anchor({"mass": 1.0, "boost_momentum": 10000.0, "knockback_resist": 2.0, "recoil_stabilization": 5.0}, 0.0) - 0.82) > 0.001:
		_fail("Unit posture anchor should clamp high anchor values.")
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
		"passive_contact_scrape_mult": 0.42,
		"attack_group_count": 6,
		"unit_body_spacing_mult": 1.0,
		"melee_stability_threshold_floor": 28.0,
	}


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_vec_close(actual, expected: Vector2, label: String) -> void:
	if not (actual is Vector2):
		_fail("%s expected Vector2, got %s." % [label, str(actual)])
		return
	var actual_vec: Vector2 = actual
	if actual_vec.distance_to(expected) > 0.001:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual_vec)])
