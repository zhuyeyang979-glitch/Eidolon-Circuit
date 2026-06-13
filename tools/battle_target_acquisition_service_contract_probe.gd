extends SceneTree

const BattleTargetAcquisitionService := preload("res://scripts/services/battle_target_acquisition_service.gd")


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
	var source := FileAccess.get_file_as_string("res://scripts/services/battle_target_acquisition_service.gd")
	if source.is_empty():
		_fail("Unable to read BattleTargetAcquisitionService.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "active_units", "all_units", "Fighter", "GpuCollisionPipeline", "_attack_part_hit", "_map_line_occluded", "_screen_from_ring", "_resolve_attack", "take_hit", "queue_free", "randf", "randi", "Time"]:
		if source.contains(forbidden):
			_fail("BattleTargetAcquisitionService contains forbidden token: %s" % forbidden)
			return

	var service := BattleTargetAcquisitionService.new()
	var direction := service.normalized_target_direction({"target_live": true, "delta": Vector2(3.0, 4.0), "fallback_direction": Vector2.LEFT})
	if not _expect(Vector2(direction.get("direction", Vector2.ZERO)).distance_to(Vector2(0.6, 0.8)) <= 0.001 and String(direction.get("reason", "")) == "delta", "delta direction mismatch: %s" % str(direction)):
		return
	var fallback := service.normalized_target_direction({"target_live": false, "delta": Vector2(3.0, 0.0), "fallback_direction": Vector2(0.0, -2.0)})
	if not _expect(Vector2(fallback.get("direction", Vector2.ZERO)).distance_to(Vector2.UP) <= 0.001 and String(fallback.get("reason", "")) == "fallback", "fallback direction mismatch: %s" % str(fallback)):
		return

	if not _expect(service.target_class({"live": true, "role": "hero"}) == "hero", "hero class mismatch"):
		return
	if not _expect(service.target_class({"live": true, "role": "puppet"}) == "puppet", "puppet class mismatch"):
		return
	if not _expect(service.target_class({"live": true, "role": "barrier", "stats": {"support_kind": "repair"}}) == "barrier_support", "support barrier class mismatch"):
		return
	if not _expect(service.target_class({"live": true, "role": "barrier", "stats": {"is_homing_launcher": true}}) == "barrier_attack", "attack barrier class mismatch"):
		return
	if not _expect(service.target_class({"live": true, "role": "barrier", "stats": {}}) == "barrier_other", "other barrier class mismatch"):
		return
	if not _expect(service.target_class_allowed("hero", ["hero"]) and not service.target_class_allowed("puppet", ["hero"]) and service.target_class_allowed("barrier_other", []), "class allowlist mismatch"):
		return

	var rejected_bullet := service.true_bullet_candidate_intent({"candidate_live": true, "has_hit": true, "target_index": 0, "distance": -0.1})
	if not _expect(String(rejected_bullet.get("action", "")) == "reject" and String(rejected_bullet.get("reason", "")) == "negative_projection", "true bullet negative projection should reject: %s" % str(rejected_bullet)):
		return
	var bullet_selection := service.true_bullet_target_selection([
		service.true_bullet_candidate_intent({"candidate_live": true, "has_hit": true, "target_index": 0, "distance": 3.0}),
		service.true_bullet_candidate_intent({"candidate_live": true, "has_hit": true, "target_index": 1, "distance": 1.25}),
	])
	if not _expect(bool(bullet_selection.get("found", false)) and int(bullet_selection.get("target_index", -1)) == 1 and String(bullet_selection.get("reason", "")) == "direct", "true bullet nearest selection mismatch: %s" % str(bullet_selection)):
		return
	var wrapped_selection := service.true_bullet_target_selection([], {"candidate_live": true, "target_index": 4, "distance": 2.0})
	if not _expect(bool(wrapped_selection.get("found", false)) and int(wrapped_selection.get("target_index", -1)) == 4 and String(wrapped_selection.get("reason", "")) == "wrapped", "wrapped fallback mismatch: %s" % str(wrapped_selection)):
		return
	var valid_index: Dictionary = service.selected_target_index_intent({"selection": {"target_index": 2}, "target_count": 3})
	if not _expect(String(valid_index.get("action", "")) == "accept" and int(valid_index.get("target_index", -1)) == 2, "valid selected index mismatch: %s" % str(valid_index)):
		return
	var negative_index: Dictionary = service.selected_target_index_intent({"selection": {"target_index": -1}, "target_count": 3})
	if not _expect(String(negative_index.get("action", "")) == "reject" and String(negative_index.get("reason", "")) == "missing_target_index", "negative selected index should reject: %s" % str(negative_index)):
		return
	var out_of_range_index: Dictionary = service.selected_target_index_intent({"selection": {"target_index": 3}, "target_count": 3})
	if not _expect(String(out_of_range_index.get("action", "")) == "reject" and String(out_of_range_index.get("reason", "")) == "target_index_out_of_range", "out-of-range selected index should reject: %s" % str(out_of_range_index)):
		return

	var blocked_class := service.missile_candidate_intent({"candidate_live": true, "target_index": 0, "target_class": "puppet", "allowed_classes": ["hero"], "distance": 1.0, "max_range": 3.0, "direction": Vector2.RIGHT, "target_direction": Vector2.RIGHT, "cone_cos": 0.5})
	if not _expect(String(blocked_class.get("reason", "")) == "class_blocked", "missile class gate mismatch: %s" % str(blocked_class)):
		return
	var out_of_range := service.missile_candidate_intent({"candidate_live": true, "target_index": 0, "target_class": "hero", "allowed_classes": ["hero"], "distance": 4.0, "max_range": 3.0, "direction": Vector2.RIGHT, "target_direction": Vector2.RIGHT, "cone_cos": 0.5})
	if not _expect(String(out_of_range.get("reason", "")) == "out_of_range", "missile range gate mismatch: %s" % str(out_of_range)):
		return
	var outside_cone := service.missile_candidate_intent({"candidate_live": true, "target_index": 0, "target_class": "hero", "allowed_classes": ["hero"], "distance": 1.0, "max_range": 3.0, "direction": Vector2.RIGHT, "target_direction": Vector2.LEFT, "cone_cos": 0.5})
	if not _expect(String(outside_cone.get("reason", "")) == "outside_cone", "missile cone gate mismatch: %s" % str(outside_cone)):
		return
	var occluded := service.missile_candidate_intent({"candidate_live": true, "target_index": 0, "target_class": "hero", "allowed_classes": ["hero"], "distance": 1.0, "max_range": 3.0, "direction": Vector2.RIGHT, "target_direction": Vector2.RIGHT, "cone_cos": 0.5, "occluded": true})
	if not _expect(String(occluded.get("reason", "")) == "occluded", "missile occlusion gate mismatch: %s" % str(occluded)):
		return
	var accepted := service.missile_candidate_intent({"candidate_live": true, "target_index": 2, "target_class": "hero", "allowed_classes": ["hero"], "distance": 1.0, "max_range": 3.0, "direction": Vector2.RIGHT, "target_direction": Vector2.RIGHT, "cone_cos": 0.5})
	if not _expect(String(accepted.get("action", "")) == "accept" and int(accepted.get("target_index", -1)) == 2, "missile accept mismatch: %s" % str(accepted)):
		return

	var near_score := service.missile_lock_score({"priority": "near_first", "distance": 1.0, "direction": Vector2.RIGHT, "target_direction": Vector2.RIGHT})
	var far_score := service.missile_lock_score({"priority": "far_first", "distance": 3.0, "direction": Vector2.RIGHT, "target_direction": Vector2.RIGHT})
	if not _expect(_approx(near_score, 1000.0) and _approx(far_score, -3000.0), "near/far score mismatch: near=%s far=%s" % [str(near_score), str(far_score)]):
		return
	var hero_score := service.missile_lock_score({"priority": "screen_hero_first", "target_class": "hero", "distance": 5.0, "screen_visible": false, "direction": Vector2.RIGHT, "target_direction": Vector2.RIGHT})
	var puppet_score := service.missile_lock_score({"priority": "screen_hero_first", "target_class": "puppet", "distance": 1.0, "screen_visible": true, "direction": Vector2.RIGHT, "target_direction": Vector2.RIGHT})
	if not _expect(hero_score < puppet_score, "screen_hero_first role priority mismatch: hero=%s puppet=%s" % [str(hero_score), str(puppet_score)]):
		return
	var missile_selection := service.missile_target_selection([
		{"action": "accept", "target_index": 0, "score": 30.0},
		{"action": "accept", "target_index": 1, "score": 12.0},
	])
	if not _expect(bool(missile_selection.get("found", false)) and int(missile_selection.get("target_index", -1)) == 1, "missile selection mismatch: %s" % str(missile_selection)):
		return

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"scripts/services/battle_target_acquisition_service.gd",
		"BattleTargetAcquisitionService.new",
		"_battle_target_acquisition_service().normalized_target_direction",
		"_battle_target_acquisition_service().target_class",
		"_battle_target_acquisition_service().target_class_allowed",
		"_battle_target_acquisition_service().true_bullet_candidate_intent",
		"_battle_target_acquisition_service().true_bullet_target_selection",
		"_battle_target_acquisition_service().selected_target_index_intent",
		"_battle_target_acquisition_service().missile_candidate_intent",
		"_battle_target_acquisition_service().missile_lock_score",
		"_battle_target_acquisition_service().missile_target_selection",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing BattleTargetAcquisitionService boundary token: %s" % token)
			return
	var stale_inline_index_guard := "var selected_index := int(selection.get(\"target_index\", -1))\n\tif selected_index < 0 or selected_index >= candidate_targets.size():\n\t\treturn null"
	if main_source.contains(stale_inline_index_guard):
		_fail("main.gd still owns target-acquisition selected-index bounds.")
		return
	print("BATTLE_TARGET_ACQUISITION_SERVICE_CONTRACT_PROBE ok")
	quit(0)
