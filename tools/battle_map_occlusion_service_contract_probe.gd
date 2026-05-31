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
	print("BATTLE_MAP_OCCLUSION_SERVICE_CONTRACT_PROBE ok")
	quit(0)
