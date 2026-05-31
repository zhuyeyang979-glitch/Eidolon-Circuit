extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_impact_query_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleImpactQueryServiceScript := preload("res://scripts/services/battle_impact_query_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing BattleImpactQueryService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name BattleImpactQueryService",
		"extends RefCounted",
		"projectile_direction_intent",
		"projectile_candidate_intent",
		"first_impact_selection",
		"gpu_hit_selection",
		"hit_slop_intent",
		"part_hit_candidate_intent",
		"part_hit_payload",
	]:
		if service_source.find(token) < 0:
			_fail("BattleImpactQueryService missing token: %s" % token)
			return
	for forbidden in [
		"Input.",
		"FileAccess",
		"DirAccess",
		"JSON.parse_string",
		"extends Node",
		"extends Control",
		"Control.new",
		"active_units",
		"all_units",
		"GpuCollisionPipeline",
		"gpu_collision",
		"Fighter",
		"_resolve_attack",
		"_attack_part_hit",
		"_submit_gpu",
		"take_hit(",
		"queue_free",
		"Time.",
		"randf",
		"randi",
	]:
		if service_source.find(forbidden) >= 0:
			_fail("BattleImpactQueryService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattleImpactQueryService = preload(\"res://scripts/services/battle_impact_query_service.gd\")",
		"var battle_impact_query_service: BattleImpactQueryService",
		"battle_impact_query_service = BattleImpactQueryService.new()",
		"func _battle_impact_query_service() -> BattleImpactQueryService",
		"_battle_impact_query_service().projectile_direction_intent",
		"_battle_impact_query_service().projectile_candidate_intent",
		"_battle_impact_query_service().first_impact_selection",
		"_battle_impact_query_service().gpu_hit_selection",
		"_battle_impact_query_service().hit_slop_intent",
		"_battle_impact_query_service().part_hit_candidate_intent",
		"_battle_impact_query_service().part_hit_payload",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate battle impact query token: %s" % token)
			return
	var service = BattleImpactQueryServiceScript.new()
	_check_direction(service)
	_check_projectile_candidates(service)
	_check_first_impact_selection(service)
	_check_gpu_selection(service)
	_check_hit_slop(service)
	_check_part_hit(service)
	print("BATTLE_IMPACT_QUERY_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _check_direction(service) -> void:
	var fallback: Dictionary = service.projectile_direction_intent({
		"direction": Vector2.ZERO,
		"fallback_direction": Vector2.LEFT * 2.0,
	})
	_assert_vec_close(fallback.get("direction", Vector2.ZERO), Vector2.LEFT, "fallback direction")
	if not bool(fallback.get("used_fallback", false)):
		_fail("Direction intent should report fallback usage.")
	var normalized: Dictionary = service.projectile_direction_intent({
		"direction": Vector2(3.0, 4.0),
		"fallback_direction": Vector2.RIGHT,
	})
	_assert_close(Vector2(normalized.get("direction", Vector2.ZERO)).length(), 1.0, "normalized direction length")
	if bool(normalized.get("used_fallback", true)):
		_fail("Direction intent should not report fallback for valid direction.")


func _check_projectile_candidates(service) -> void:
	_assert_eq(String(service.projectile_candidate_intent({
		"candidate_live": false,
	}).get("reason", "")), "candidate_gone", "dead candidate reject")
	_assert_eq(String(service.projectile_candidate_intent({
		"true_bullet": true,
		"locked_target_live": true,
		"is_locked_target": true,
		"blocked_before_locked": true,
	}).get("reason", "")), "locked_target_blocked", "locked target blocked")
	_assert_eq(String(service.projectile_candidate_intent({
		"true_bullet": true,
		"locked_target_live": true,
		"is_locked_target": false,
		"candidate_before_locked": false,
	}).get("reason", "")), "behind_locked_target", "candidate behind locked")
	_assert_eq(String(service.projectile_candidate_intent({"projection": -0.2}).get("reason", "")), "negative_projection", "negative projection")
	_assert_eq(String(service.projectile_candidate_intent({"projection": 0.01}).get("action", "")), "accept", "valid projectile candidate")


func _check_first_impact_selection(service) -> void:
	var selected: Dictionary = service.first_impact_selection([
		{"action": "accept", "distance": 4.0, "id": "far"},
		{"action": "reject", "distance": 0.5, "id": "reject"},
		{"action": "accept", "projection": 1.25, "id": "near"},
	])
	_assert_eq(String(selected.get("id", "")), "near", "nearest projection selected")
	_assert_close(float(selected.get("distance", 0.0)), 1.25, "nearest distance value")
	if not service.first_impact_selection([{"action": "reject", "distance": 0.1}]).is_empty():
		_fail("Rejected-only first impact selection should be empty.")


func _check_gpu_selection(service) -> void:
	var attack_collider := {"part_kind": "barrel", "terminal_weapon_kind": "rifle", "center": Vector2.ZERO}
	var target_collider_a := {"part_index": 2, "part_kind": "limb", "name": "ARM", "torso_unit_index": 1, "terminal_weapon_kind": "blade", "center": Vector2(2.0, 0.0)}
	var target_collider_b := {"part_index": 3, "part_kind": "core", "name": "CORE", "center": Vector2(1.0, 0.0)}
	var selected: Dictionary = service.gpu_hit_selection({
		"attack_collider": attack_collider,
		"gpu_gap": -0.04,
		"hits": [
			{"collider_index": -1, "distance": 0.1},
			{"collider_index": 0, "distance": 0.7, "position": Vector2(7.0, 0.0), "normal": Vector2.RIGHT},
			{"collider_index": 1, "distance": 0.2, "position": Vector2(2.0, 0.0), "normal": Vector2.LEFT},
			{"collider_index": 2, "distance": 0.05},
		],
		"entries": [
			{"query": target_collider_a, "target_live": true, "occluded": true, "target_position": Vector2(7.0, 0.0)},
			{"query": target_collider_b, "target_live": true, "occluded": false, "target_position": Vector2(2.0, 0.0)},
		],
	})
	_assert_eq(int(selected.get("entry_index", -1)), 1, "gpu nearest non-occluded entry")
	_assert_close(float(selected.get("distance", 0.0)), 0.2, "gpu nearest distance")
	var hit: Dictionary = Dictionary(selected.get("hit", {}))
	_assert_eq(int(hit.get("part_index", -1)), 3, "gpu hit part index")
	_assert_eq(String(hit.get("attacker_part_kind", "")), "barrel", "gpu attacker part kind")
	if not bool(hit.get("attacker_runtime_topology", false)) or not bool(hit.get("gpu_query_hit", false)):
		_fail("GPU hit payload should mark runtime topology and gpu hit: %s" % str(hit))
	_assert_vec_close(hit.get("contact_normal", Vector2.ZERO), Vector2.LEFT, "gpu contact normal")


func _check_hit_slop(service) -> void:
	_assert_close(float(service.hit_slop_intent({"projectile": false}).get("hit_slop", 0.0)), 0.16, "melee slop")
	_assert_close(float(service.hit_slop_intent({
		"projectile": false,
		"direct_runtime_hit": true,
		"runtime_required_overlap": 0.035,
	}).get("hit_slop", 0.0)), -0.035, "direct runtime melee slop")
	_assert_close(float(service.hit_slop_intent({
		"projectile": true,
		"lane_range": 0.5,
		"projectile_damage_type": "bullet",
	}).get("hit_slop", 0.0)), 0.04, "bullet projectile slop")
	_assert_close(float(service.hit_slop_intent({
		"projectile": true,
		"lane_range": 0.5,
		"projectile_damage_type": "chemical",
	}).get("hit_slop", 0.0)), 0.11, "chemical projectile slop")
	_assert_close(float(service.hit_slop_intent({
		"projectile": true,
		"direct_runtime_hit": true,
		"lane_range": 0.5,
	}).get("hit_slop", 0.0)), 0.0, "direct runtime projectile slop")


func _check_part_hit(service) -> void:
	_assert_eq(String(service.part_hit_candidate_intent({
		"target_collider_valid": false,
	}).get("reason", "")), "invalid_target_collider", "invalid collider reject")
	_assert_eq(String(service.part_hit_candidate_intent({
		"projectile": true,
		"has_direction": true,
		"direction": Vector2.RIGHT,
		"to_part": Vector2.LEFT,
		"gap": -1.0,
		"hit_slop": 0.0,
		"best_gap": 999.0,
	}).get("reason", "")), "behind_projectile", "behind projectile reject")
	_assert_eq(String(service.part_hit_candidate_intent({
		"gap": 0.4,
		"hit_slop": 0.1,
		"best_gap": 999.0,
	}).get("reason", "")), "outside_slop", "outside slop reject")
	_assert_eq(String(service.part_hit_candidate_intent({
		"gap": 0.08,
		"hit_slop": 0.1,
		"best_gap": 0.05,
	}).get("reason", "")), "not_best", "not best reject")
	_assert_eq(String(service.part_hit_candidate_intent({
		"gap": -0.02,
		"hit_slop": 0.1,
		"best_gap": 999.0,
	}).get("action", "")), "accept", "valid part hit")
	var payload: Dictionary = service.part_hit_payload({
		"attack_collider": {"part_kind": "blade", "terminal_weapon_kind": "sword"},
		"target_collider": {"part_index": 4, "part_kind": "limb", "name": "LEG", "torso_unit_index": 0, "terminal_weapon_kind": "shield"},
		"position": Vector2(3.0, 4.0),
		"gap": -0.03,
		"contact_normal": Vector2.ZERO,
		"fallback_direction": Vector2.DOWN,
	})
	_assert_eq(int(payload.get("part_index", -1)), 4, "payload part index")
	_assert_eq(String(payload.get("part_name", "")), "LEG", "payload part name")
	_assert_eq(String(payload.get("attacker_terminal_weapon_kind", "")), "sword", "payload attacker terminal")
	_assert_eq(String(payload.get("target_terminal_weapon_kind", "")), "shield", "payload target terminal")
	_assert_vec_close(payload.get("position", Vector2.ZERO), Vector2(3.0, 4.0), "payload position")
	_assert_vec_close(payload.get("contact_normal", Vector2.ZERO), Vector2.DOWN, "payload fallback normal")


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_close(actual: float, expected: float, label: String, tolerance: float = 0.001) -> void:
	if absf(actual - expected) > tolerance:
		_fail("%s expected %.4f, got %.4f." % [label, expected, actual])


func _assert_vec_close(actual, expected: Vector2, label: String, tolerance: float = 0.001) -> void:
	if not (actual is Vector2):
		_fail("%s expected Vector2, got %s." % [label, str(actual)])
		return
	if Vector2(actual).distance_to(expected) > tolerance:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])
