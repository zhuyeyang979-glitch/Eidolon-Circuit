extends SceneTree

const BattleMapOcclusionService := preload("res://scripts/services/battle_map_occlusion_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _approx(a: float, b: float, tolerance: float = 0.001) -> bool:
	return absf(a - b) <= tolerance


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/battle_map_occlusion_service.gd")
	if source.is_empty():
		_fail("Unable to read BattleMapOcclusionService.")
		return
	if not source.contains("func one_way_projectile_pass_intent"):
		_fail("BattleMapOcclusionService missing one_way_projectile_pass_intent.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "active_units", "all_units", "GpuCollisionPipeline", "Fighter", "_resolve_attack", "_attack_part_hit", "take_hit", "queue_free", "_one_way_shield_allows_projectile", "_unit_part_colliders", "randf", "randi", "Time", "_spawn_hit_effect", "_play_sfx"]:
		if source.contains(forbidden):
			_fail("BattleMapOcclusionService contains forbidden token: %s" % forbidden)
			return
	var service := BattleMapOcclusionService.new()

	if not _expect(service.occlusion_kind_for_data({"is_one_way_shield": true}) == "one_way", "one-way kind mismatch"):
		return
	if not _expect(service.occlusion_kind_for_data({"is_cage_wall": true}) == "cage", "cage kind mismatch"):
		return
	if not _expect(service.occlusion_kind_for_data({"reflect_projectiles": true}) == "reflector", "reflector kind mismatch"):
		return
	if not _expect(service.occlusion_kind_for_data({"material_class": "signal_jammer"}) == "solid", "signal jammer should be solid"):
		return
	if not _expect(service.occlusion_kind_for_data({"shape": "coolant_field", "panel_family": "support"}) == "none", "support field should not occlude"):
		return

	var allied_pass: Dictionary = service.one_way_projectile_pass_intent({
		"pass_mode": "ally",
		"attacker_owner": 1,
		"shield_owner": 1,
	})
	if not _expect(bool(allied_pass.get("passes", false)) and String(allied_pass.get("reason", "")) == "allied_owner", "allied one-way pass mismatch: %s" % str(allied_pass)):
		return
	var iff_block: Dictionary = service.one_way_projectile_pass_intent({
		"pass_mode": "iff",
		"attacker_owner": 2,
		"shield_owner": 1,
	})
	if not _expect(not bool(iff_block.get("passes", true)) and String(iff_block.get("reason", "")) == "foreign_owner", "IFF one-way block mismatch: %s" % str(iff_block)):
		return
	var enemy_pass: Dictionary = service.one_way_projectile_pass_intent({
		"pass_mode": "enemy",
		"attacker_owner": 2,
		"shield_owner": 1,
	})
	if not _expect(bool(enemy_pass.get("passes", false)) and String(enemy_pass.get("reason", "")) == "enemy_owner", "enemy one-way pass mismatch: %s" % str(enemy_pass)):
		return
	var enemy_block: Dictionary = service.one_way_projectile_pass_intent({
		"pass_mode": "enemy",
		"attacker_owner": 1,
		"shield_owner": 1,
	})
	if not _expect(not bool(enemy_block.get("passes", true)) and String(enemy_block.get("reason", "")) == "same_owner", "same-owner enemy-mode block mismatch: %s" % str(enemy_block)):
		return
	var directional_pass: Dictionary = service.one_way_projectile_pass_intent({
		"attack_direction": Vector2.RIGHT,
		"attacker_facing": -1.0,
		"shield_facing": 1.0,
	})
	if not _expect(bool(directional_pass.get("passes", false)) and not bool(directional_pass.get("used_attacker_facing", true)), "directional one-way pass mismatch: %s" % str(directional_pass)):
		return
	var reverse_block: Dictionary = service.one_way_projectile_pass_intent({
		"attack_direction": Vector2.RIGHT,
		"attacker_facing": 1.0,
		"shield_facing": 1.0,
		"pass_direction": "reverse",
	})
	if not _expect(not bool(reverse_block.get("passes", true)), "reverse one-way direction should block forward fire: %s" % str(reverse_block)):
		return
	var facing_fallback: Dictionary = service.one_way_projectile_pass_intent({
		"attack_direction": Vector2.UP,
		"attacker_facing": -1.0,
		"shield_facing": -1.0,
	})
	if not _expect(bool(facing_fallback.get("passes", false)) and bool(facing_fallback.get("used_attacker_facing", false)), "zero-X direction should use attacker facing: %s" % str(facing_fallback)):
		return

	var event_path := service.path_collider_for_event({
		"start": Vector2(2.0, 0.5),
		"direction": Vector2.ZERO,
		"fallback_direction": Vector2.RIGHT,
		"range": 3.0,
		"projectile_width_m": 0.04,
		"lane_range": 0.12,
	})
	if not _expect(event_path.get("a", Vector2.ZERO) == Vector2(2.0, 0.5) and event_path.get("b", Vector2.ZERO) == Vector2(5.0, 0.5), "event path fallback direction mismatch: %s" % str(event_path)):
		return
	if not _expect(_approx(float(event_path.get("radius", 0.0)), 0.06), "event path radius mismatch: %s" % str(event_path)):
		return
	var between := service.path_collider_between({"start": Vector2(1.0, -0.1), "delta": Vector2(2.5, 0.2), "lane_range": 0.08})
	if not _expect(between.get("b", Vector2.ZERO) == Vector2(3.5, 0.1) and _approx(float(between.get("radius", 0.0)), 0.04), "between path mismatch: %s" % str(between)):
		return
	if not _expect(service.path_collider_between({"start": Vector2.ZERO, "delta": Vector2(0.001, 0.0)}).is_empty(), "short between path should be invalid"):
		return

	var gap_skip := service.blocker_candidate_intent({"kind": "solid", "gap": 0.02, "path_length": 2.0})
	if not _expect(String(gap_skip.get("action", "")) == "reject" and String(gap_skip.get("reason", "")) == "outside_path", "gap skip mismatch: %s" % str(gap_skip)):
		return
	var pass_skip := service.blocker_candidate_intent({"kind": "one_way", "gap": -0.01, "one_way_pass": true, "path_length": 2.0})
	if not _expect(String(pass_skip.get("reason", "")) == "one_way_pass", "one-way pass skip mismatch: %s" % str(pass_skip)):
		return
	var projection_skip := service.blocker_candidate_intent({
		"kind": "solid",
		"gap": -0.01,
		"start": Vector2.ZERO,
		"direction": Vector2.RIGHT,
		"path_length": 2.0,
		"center": Vector2(3.0, 0.0),
		"extent": 0.1,
	})
	if not _expect(String(projection_skip.get("reason", "")) == "outside_projection", "projection skip mismatch: %s" % str(projection_skip)):
		return
	var far := service.blocker_candidate_intent({
		"kind": "solid",
		"blocker_name": "FAR WALL",
		"gap": -0.01,
		"start": Vector2.ZERO,
		"direction": Vector2.RIGHT,
		"path_length": 4.0,
		"center": Vector2(3.0, 0.0),
		"extent": 0.2,
		"candidate_index": 1,
		"collider": {"shape": "circle", "center": Vector2(3.0, 0.0), "radius": 0.2},
	})
	var near := service.blocker_candidate_intent({
		"kind": "cage",
		"blocker_name": "NEAR CAGE",
		"gap": -0.01,
		"start": Vector2.ZERO,
		"direction": Vector2.RIGHT,
		"path_length": 4.0,
		"center": Vector2(1.2, 0.0),
		"extent": 0.2,
		"candidate_index": 0,
		"collider": {"shape": "circle", "center": Vector2(1.2, 0.0), "radius": 0.2},
	})
	var query := service.occlusion_query_from_candidates({"candidates": [far, near]})
	if not _expect(String(query.get("kind", "")) == "cage" and String(query.get("blocker_name", "")) == "NEAR CAGE" and int(query.get("candidate_index", -1)) == 0, "nearest query mismatch: %s" % str(query)):
		return
	if not _expect(service.line_occluded(query) and not service.line_of_sight_clear(query), "line helpers mismatch"):
		return
	if not _expect(service.occlusion_kind_from_query({}) == "none" and not service.line_occluded({}) and service.line_of_sight_clear({}), "empty query helpers mismatch"):
		return

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"scripts/services/battle_map_occlusion_service.gd",
		"BattleMapOcclusionService.new",
		"_battle_map_occlusion_service().occlusion_kind_for_data",
		"_battle_map_occlusion_service().one_way_projectile_pass_intent({",
		"_battle_map_occlusion_service().path_collider_for_event",
		"_battle_map_occlusion_service().path_collider_between",
		"_battle_map_occlusion_service().blocker_candidate_intent",
		"_battle_map_occlusion_service().occlusion_query_from_candidates",
		"_battle_map_occlusion_service().occlusion_kind_from_query",
		"_battle_map_occlusion_service().line_occluded",
		"_battle_map_occlusion_service().line_of_sight_clear",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing BattleMapOcclusionService boundary token: %s" % token)
			return
	var stale_one_way_pass_policy := "var mode := String(shield.stats.get(\"shield_pass_mode\", \"directional\"))\n\tif mode in [\"iff\", \"ally\"]:\n\t\treturn int(attacker.owner_id) == int(shield.owner_id)\n\tif mode == \"enemy\":\n\t\treturn int(attacker.owner_id) != int(shield.owner_id)\n\tvar dir_sign := signf(attack_direction.x)"
	if main_source.contains(stale_one_way_pass_policy):
		_fail("main.gd should not keep duplicate one-way projectile pass policy.")
		return
	print("BATTLE_MAP_OCCLUSION_SERVICE_CONTRACT_PROBE ok")
	quit(0)
