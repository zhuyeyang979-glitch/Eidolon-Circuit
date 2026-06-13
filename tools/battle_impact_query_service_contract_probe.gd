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
		"projectile_projection_intent",
		"true_bullet_before_locked_target_intent",
		"gpu_projectile_query_ray_intent",
		"gpu_projectile_query_payload",
		"gpu_projectile_target_entry_payload",
		"projectile_candidate_intent",
		"first_impact_selection",
		"func projectile_selection_result_intent",
		"func projectile_final_impact_payload",
		"gpu_hit_selection",
		"gpu_projectile_selection_result_intent",
		"gpu_projectile_final_impact_payload",
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
		"_battle_impact_query_service().projectile_projection_intent({",
		"_battle_impact_query_service().true_bullet_before_locked_target_intent({",
		"_battle_impact_query_service().gpu_projectile_query_ray_intent({",
		"_battle_impact_query_service().gpu_projectile_query_payload({",
		"_battle_impact_query_service().gpu_projectile_target_entry_payload({",
		"_battle_impact_query_service().projectile_candidate_intent",
		"_battle_impact_query_service().first_impact_selection",
		"_battle_impact_query_service().projectile_selection_result_intent({",
		"_battle_impact_query_service().projectile_final_impact_payload({",
		"_battle_impact_query_service().gpu_hit_selection",
		"_battle_impact_query_service().gpu_projectile_selection_result_intent({",
		"_battle_impact_query_service().gpu_projectile_final_impact_payload({",
		"_battle_impact_query_service().hit_slop_intent",
		"_battle_impact_query_service().part_hit_candidate_intent",
		"_battle_impact_query_service().part_hit_payload",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate battle impact query token: %s" % token)
			return
	for stale_fragment in [
		"var normalized := direction.normalized() if direction.length() > 0.01 else _unit_forward_vector(attacker)",
		"return delta.dot(normalized)",
		"return delta.dot(direction.normalized() if direction.length() > 0.01 else _unit_forward_vector(attacker))",
		"return unit_distance >= 0.0 and unit_distance <= target_distance - 0.035",
		"var range := maxf(float(event.get(\"range\", event.get(\"projectile_range\", start.distance_to(end)))), start.distance_to(end))",
		"var ray := GameplayTransform.projectile_ray(start, direction, range)",
		"\"radius\": maxf(0.0, float(attack_collider.get(\"radius\", event.get(\"lane_range\", 0.0))))",
		"\"owner_team_key\": int(attacker.owner_id),\n\t\t\"query_id\": 0,\n\t\t\"include_friendly\": include_friendly,\n\t}]",
		"entry.erase(\"unit\")",
		"entry[\"target_index\"] = entry_targets.size() - 1",
		"var selected_entry: Dictionary = Dictionary(selection.get(\"entry\", {}))",
		"if selected_index < 0 or selected_index >= entry_targets.size()",
		"\"position\": selection_result.get(\"position\", Vector2(selected_target.ring_pos, selected_target.lane))",
		"\"position\": selection.get(\"position\", Vector2(selected_target.ring_pos, selected_target.lane))",
	]:
		if main_source.find(stale_fragment) >= 0:
			_fail("main.gd should not keep duplicate battle impact query logic: %s" % stale_fragment)
			return
	var service = BattleImpactQueryServiceScript.new()
	_check_direction(service)
	_check_projection(service)
	_check_true_bullet_before_locked_target(service)
	_check_gpu_projectile_query_ray(service)
	_check_gpu_projectile_query_payload(service)
	_check_gpu_projectile_target_entry_payload(service)
	_check_projectile_candidates(service)
	_check_first_impact_selection(service)
	_check_projectile_selection_result(service)
	_check_projectile_final_impact_payload(service)
	_check_gpu_selection(service)
	_check_gpu_projectile_selection_result(service)
	_check_gpu_projectile_final_impact_payload(service)
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


func _check_projection(service) -> void:
	var projection: Dictionary = service.projectile_projection_intent({
		"attacker_live": true,
		"delta": Vector2(4.0, 3.0),
		"direction": Vector2.RIGHT * 2.0,
		"fallback_direction": Vector2.LEFT,
		"missing_projection": 999999.0,
	})
	_assert_close(float(projection.get("projection", 0.0)), 4.0, "projectile projection")
	if bool(projection.get("used_fallback", true)):
		_fail("Projection should not use fallback when direction is valid.")
	var fallback: Dictionary = service.projectile_projection_intent({
		"attacker_live": true,
		"delta": Vector2(4.0, 3.0),
		"direction": Vector2.ZERO,
		"fallback_direction": Vector2.UP,
		"missing_projection": 999999.0,
	})
	_assert_close(float(fallback.get("projection", 0.0)), -3.0, "projectile fallback projection")
	if not bool(fallback.get("used_fallback", false)):
		_fail("Projection should report fallback usage.")
	_assert_close(float(service.projectile_projection_intent({
		"attacker_live": false,
		"delta": Vector2(4.0, 3.0),
		"direction": Vector2.RIGHT,
		"missing_projection": 12345.0,
	}).get("projection", 0.0)), 12345.0, "projectile projection dead attacker")


func _check_true_bullet_before_locked_target(service) -> void:
	var before: Dictionary = service.true_bullet_before_locked_target_intent({
		"unit_distance": 2.0,
		"target_distance": 4.0,
		"clearance": 0.035,
	})
	if not bool(before.get("before_locked_target", false)) or String(before.get("reason", "")) != "before_locked_target":
		_fail("True bullet unit before locked target should pass: %s" % str(before))
	var negative: Dictionary = service.true_bullet_before_locked_target_intent({
		"unit_distance": -0.01,
		"target_distance": 4.0,
	})
	if bool(negative.get("before_locked_target", true)) or String(negative.get("reason", "")) != "behind_attacker":
		_fail("Negative projection should reject true bullet blocker: %s" % str(negative))
	var too_close: Dictionary = service.true_bullet_before_locked_target_intent({
		"unit_distance": 3.98,
		"target_distance": 4.0,
		"clearance": 0.035,
	})
	if bool(too_close.get("before_locked_target", true)) or String(too_close.get("reason", "")) != "at_or_beyond_locked_target":
		_fail("Unit inside clearance should not be before locked target: %s" % str(too_close))


func _check_gpu_projectile_query_ray(service) -> void:
	var extended: Dictionary = service.gpu_projectile_query_ray_intent({
		"start": Vector2(1.0, 2.0),
		"end": Vector2(3.0, 2.0),
		"direction": Vector2(3.0, 4.0),
		"requested_range": 5.0,
	})
	_assert_vec_close(extended.get("start", Vector2.ZERO), Vector2(1.0, 2.0), "gpu query ray start")
	_assert_vec_close(extended.get("end", Vector2.ZERO), Vector2(4.0, 6.0), "gpu query ray extended end")
	_assert_vec_close(extended.get("direction", Vector2.ZERO), Vector2(0.6, 0.8), "gpu query ray direction")
	_assert_close(float(extended.get("range", 0.0)), 5.0, "gpu query ray requested range")
	if not bool(extended.get("extended", false)):
		_fail("GPU projectile query ray should report extension for a valid direction.")
	var collider_minimum: Dictionary = service.gpu_projectile_query_ray_intent({
		"start": Vector2(1.0, 2.0),
		"end": Vector2(4.0, 2.0),
		"direction": Vector2.RIGHT,
		"requested_range": 1.0,
	})
	_assert_vec_close(collider_minimum.get("end", Vector2.ZERO), Vector2(4.0, 2.0), "gpu query ray collider minimum")
	_assert_close(float(collider_minimum.get("range", 0.0)), 3.0, "gpu query ray collider range")
	var unchanged: Dictionary = service.gpu_projectile_query_ray_intent({
		"start": Vector2(1.0, 2.0),
		"end": Vector2(3.0, 2.0),
		"direction": Vector2.ZERO,
		"requested_range": 9.0,
	})
	_assert_vec_close(unchanged.get("end", Vector2.ZERO), Vector2(3.0, 2.0), "gpu query ray zero-direction end")
	_assert_vec_close(unchanged.get("direction", Vector2.RIGHT), Vector2.ZERO, "gpu query ray zero direction")
	if bool(unchanged.get("extended", true)):
		_fail("GPU projectile query ray should keep the collider endpoint for a zero direction.")


func _check_gpu_projectile_query_payload(service) -> void:
	var payload: Dictionary = service.gpu_projectile_query_payload({
		"start": Vector2(1.0, 2.0),
		"end": Vector2(5.0, 6.0),
		"radius": 0.25,
		"owner_unit_key": 7,
		"owner_team_key": 3,
		"query_id": 11,
		"include_friendly": true,
	})
	_assert_vec_close(payload.get("start", Vector2.ZERO), Vector2(1.0, 2.0), "gpu query payload start")
	_assert_vec_close(payload.get("end", Vector2.ZERO), Vector2(5.0, 6.0), "gpu query payload end")
	_assert_close(float(payload.get("radius", 0.0)), 0.25, "gpu query payload radius")
	_assert_eq(int(payload.get("owner_unit_key", -1)), 7, "gpu query payload owner unit")
	_assert_eq(int(payload.get("owner_team_key", -1)), 3, "gpu query payload owner team")
	_assert_eq(int(payload.get("query_id", -1)), 11, "gpu query payload id")
	_assert_eq(bool(payload.get("include_friendly", false)), true, "gpu query payload friendly flag")
	var clamped: Dictionary = service.gpu_projectile_query_payload({
		"start": Vector2.ZERO,
		"end": Vector2.RIGHT,
		"radius": -0.5,
	})
	_assert_close(float(clamped.get("radius", -1.0)), 0.0, "gpu query payload clamped radius")
	_assert_eq(int(clamped.get("owner_unit_key", -1)), 1, "gpu query payload default owner unit")
	_assert_eq(int(clamped.get("query_id", -1)), 0, "gpu query payload default id")
	_assert_eq(bool(clamped.get("include_friendly", true)), false, "gpu query payload default friendly flag")


func _check_gpu_projectile_target_entry_payload(service) -> void:
	var source := {
		"unit": "runtime-node-reference",
		"query": {"part_index": 4, "part_kind": "limb"},
		"custom_tag": "preserved",
	}
	var payload: Dictionary = service.gpu_projectile_target_entry_payload({
		"entry": source,
		"target_index": 3,
		"target_live": true,
		"occluded": true,
		"target_position": Vector2(7.0, 8.0),
		"has_target_position": true,
	})
	if payload.has("unit"):
		_fail("GPU target entry payload should remove runtime unit references: %s" % str(payload))
	if not source.has("unit"):
		_fail("GPU target entry payload should not mutate the source dictionary.")
	_assert_eq(String(payload.get("custom_tag", "")), "preserved", "gpu target entry custom field")
	_assert_eq(int(payload.get("target_index", -1)), 3, "gpu target entry index")
	_assert_eq(bool(payload.get("target_live", false)), true, "gpu target entry live flag")
	_assert_eq(bool(payload.get("occluded", false)), true, "gpu target entry occluded flag")
	_assert_vec_close(payload.get("target_position", Vector2.ZERO), Vector2(7.0, 8.0), "gpu target entry position")
	var dead: Dictionary = service.gpu_projectile_target_entry_payload({
		"entry": {"unit": "gone", "query": {"part_index": 2}},
		"target_index": 1,
		"target_live": false,
		"occluded": false,
		"has_target_position": false,
	})
	if dead.has("unit") or dead.has("target_position"):
		_fail("Dead GPU target entry should remove the unit and omit target position: %s" % str(dead))
	_assert_eq(bool(dead.get("target_live", true)), false, "dead gpu target entry live flag")


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


func _check_projectile_selection_result(service) -> void:
	var empty: Dictionary = service.projectile_selection_result_intent({
		"selection": {},
		"target_count": 2,
	})
	_assert_eq(String(empty.get("action", "")), "reject", "empty projectile selection action")
	_assert_eq(String(empty.get("reason", "")), "no_selection", "empty projectile selection reason")
	var invalid: Dictionary = service.projectile_selection_result_intent({
		"selection": {"target_index": 3},
		"target_count": 3,
	})
	_assert_eq(String(invalid.get("reason", "")), "invalid_target_index", "invalid projectile selection index")
	var valid: Dictionary = service.projectile_selection_result_intent({
		"selection": {
			"target_index": 1,
			"hit": {"part_index": 2, "part_kind": "limb"},
			"position": Vector2(4.0, 5.0),
			"distance": 6.0,
		},
		"target_count": 2,
	})
	_assert_eq(String(valid.get("action", "")), "accept", "valid projectile selection action")
	_assert_eq(int(valid.get("target_index", -1)), 1, "valid projectile selection index")
	_assert_eq(int(Dictionary(valid.get("hit", {})).get("part_index", -1)), 2, "valid projectile selection hit")
	_assert_vec_close(valid.get("position", Vector2.ZERO), Vector2(4.0, 5.0), "valid projectile selection position")
	_assert_close(float(valid.get("distance", 0.0)), 6.0, "valid projectile selection distance")
	if not bool(valid.get("has_position", false)):
		_fail("Valid projectile selection should report its explicit position.")


func _check_projectile_final_impact_payload(service) -> void:
	var dead: Dictionary = service.projectile_final_impact_payload({
		"target_live": false,
		"selection_result": {"hit": {"part_index": 1}, "position": Vector2(1.0, 2.0), "distance": 3.0},
		"target_position": Vector2(9.0, 9.0),
	})
	_assert_eq(String(dead.get("reason", "")), "target_gone", "dead projectile final payload reason")
	var explicit: Dictionary = service.projectile_final_impact_payload({
		"target_live": true,
		"selection_result": {"hit": {"part_index": 4}, "position": Vector2(5.0, 6.0), "distance": 2.25, "has_position": true},
		"target_position": Vector2(9.0, 9.0),
	})
	_assert_eq(String(explicit.get("action", "")), "accept", "explicit projectile final payload action")
	_assert_vec_close(explicit.get("position", Vector2.ZERO), Vector2(5.0, 6.0), "explicit projectile final payload position")
	_assert_close(float(explicit.get("distance", 0.0)), 2.25, "explicit projectile final payload distance")
	var fallback: Dictionary = service.projectile_final_impact_payload({
		"target_live": true,
		"selection_result": {"hit": {"part_index": 3}, "distance": 1.5, "has_position": false},
		"target_position": Vector2(7.0, 8.0),
	})
	_assert_vec_close(fallback.get("position", Vector2.ZERO), Vector2(7.0, 8.0), "fallback projectile final payload position")


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


func _check_gpu_projectile_selection_result(service) -> void:
	var empty: Dictionary = service.gpu_projectile_selection_result_intent({
		"selection": {},
		"target_count": 2,
	})
	_assert_eq(String(empty.get("action", "")), "reject", "empty gpu selection action")
	_assert_eq(String(empty.get("reason", "")), "no_selection", "empty gpu selection reason")
	var invalid: Dictionary = service.gpu_projectile_selection_result_intent({
		"selection": {"entry": {"target_index": 2}},
		"target_count": 2,
	})
	_assert_eq(String(invalid.get("reason", "")), "invalid_target_index", "invalid gpu selection index")
	var valid: Dictionary = service.gpu_projectile_selection_result_intent({
		"selection": {
			"entry": {"target_index": 1},
			"hit": {"part_index": 4, "part_kind": "limb"},
			"position": Vector2(6.0, 7.0),
			"distance": 2.5,
		},
		"target_count": 3,
		"missing_distance": 999999.0,
	})
	_assert_eq(String(valid.get("action", "")), "accept", "valid gpu selection action")
	_assert_eq(int(valid.get("target_index", -1)), 1, "valid gpu selection target index")
	_assert_eq(int(Dictionary(valid.get("hit", {})).get("part_index", -1)), 4, "valid gpu selection hit")
	_assert_vec_close(valid.get("position", Vector2.ZERO), Vector2(6.0, 7.0), "valid gpu selection position")
	_assert_close(float(valid.get("distance", 0.0)), 2.5, "valid gpu selection distance")
	if not bool(valid.get("has_position", false)):
		_fail("Valid GPU selection should report its explicit position.")
	var fallback: Dictionary = service.gpu_projectile_selection_result_intent({
		"selection": {"entry": {"target_index": 0}, "hit": {}, "distance": 1.0},
		"target_count": 1,
	})
	if bool(fallback.get("has_position", true)) or fallback.has("position"):
		_fail("GPU selection without a position should leave fallback sampling to main.gd: %s" % str(fallback))


func _check_gpu_projectile_final_impact_payload(service) -> void:
	var dead: Dictionary = service.gpu_projectile_final_impact_payload({
		"target_live": false,
		"selection_result": {"hit": {"part_index": 1}, "position": Vector2(1.0, 2.0), "distance": 3.0},
		"target_position": Vector2(9.0, 9.0),
	})
	_assert_eq(String(dead.get("action", "")), "reject", "dead gpu final payload action")
	_assert_eq(String(dead.get("reason", "")), "target_gone", "dead gpu final payload reason")
	var explicit: Dictionary = service.gpu_projectile_final_impact_payload({
		"target_live": true,
		"selection_result": {
			"hit": {"part_index": 4, "part_kind": "core"},
			"position": Vector2(5.0, 6.0),
			"distance": 2.25,
			"has_position": true,
		},
		"target_position": Vector2(9.0, 9.0),
		"missing_distance": 999999.0,
	})
	_assert_eq(String(explicit.get("action", "")), "accept", "explicit gpu final payload action")
	_assert_eq(int(Dictionary(explicit.get("hit", {})).get("part_index", -1)), 4, "explicit gpu final payload hit")
	_assert_vec_close(explicit.get("position", Vector2.ZERO), Vector2(5.0, 6.0), "explicit gpu final payload position")
	_assert_close(float(explicit.get("distance", 0.0)), 2.25, "explicit gpu final payload distance")
	var fallback: Dictionary = service.gpu_projectile_final_impact_payload({
		"target_live": true,
		"selection_result": {"hit": {"part_index": 2}, "distance": 1.5, "has_position": false},
		"target_position": Vector2(7.0, 8.0),
	})
	_assert_vec_close(fallback.get("position", Vector2.ZERO), Vector2(7.0, 8.0), "fallback gpu final payload position")
	_assert_close(float(fallback.get("distance", 0.0)), 1.5, "fallback gpu final payload distance")


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
