extends SceneTree

const SERVICE_PATH := "res://scripts/services/star_soul_bp_service.gd"
const DESIGN_PATH := "res://docs/reports/2026-06-24-mobius-bp-star-soul-design.md"
const PLAN_PATH := "res://docs/plans/2026-06-24-mobius-bp-star-soul-runtime.md"

var failed := false


func _init() -> void:
	_require(FileAccess.file_exists(SERVICE_PATH), "Missing StarSoulBPService script.")
	_require(FileAccess.file_exists(DESIGN_PATH), "Missing Mobius BP design document.")
	_require(FileAccess.file_exists(PLAN_PATH), "Missing Mobius BP implementation plan.")
	if failed:
		quit(1)
		return

	var ServiceScript = load(SERVICE_PATH)
	_require(ServiceScript != null, "Cannot load StarSoulBPService script.")
	if failed:
		quit(1)
		return
	var service = ServiceScript.new()

	var map_spec: Dictionary = service.battle_map_spec(Vector2(1920.0, 1080.0))
	_require(String(map_spec.get("topology", "")) == "mobius_strip", "Battle map should be a Mobius strip.")
	_require(is_equal_approx(float(map_spec.get("circumference", 0.0)), 3840.0), "Map length should be two player screens.")
	_require(is_equal_approx(float(map_spec.get("lane_height", 0.0)), 1620.0), "Map height should be 1.5 player screens.")
	_require(service.spawn_point_for_player(1, Vector2(1920.0, 1080.0)) == Vector2.ZERO, "P1 spawn should be the local origin.")
	_require(service.spawn_point_for_player(2, Vector2(1920.0, 1080.0)) == Vector2(1920.0, 0.0), "P2 spawn should be one screen away.")
	_require(service.point_in_home_half(80.0, 1, Vector2(1920.0, 1080.0)), "P1 nearby point should be in P1 half.")
	_require(service.point_in_home_half(3760.0, 1, Vector2(1920.0, 1080.0)), "P1 half should wrap around the Mobius seam.")
	_require(not service.point_in_home_half(1920.0, 1, Vector2(1920.0, 1080.0)), "Enemy spawn should not be in P1 half.")

	var turns: Array = service.draft_turns(2, 3)
	_require(_players(turns) == [2, 1, 2, 1, 2, 1], "BP turns should alternate from first player: %s" % str(turns))

	var catalog: Dictionary = service.catalog_by_id()
	for required_id in [
		"defense_tower_a",
		"defense_tower_f",
		"punishment_tower_f",
		"cart_a",
		"wandering_giant_a",
		"traitor_a",
		"loyalist_a",
		"rebel_a",
		"lord_a",
		"tyrant_a",
		"coward_a",
	]:
		_require(catalog.has(required_id), "Catalog missing %s." % required_id)
	_require(float(Dictionary(catalog.get("defense_tower_a", {})).get("duration", 0.0)) == 50.0, "Defense tower A should last 50 seconds.")
	_require(int(Dictionary(catalog.get("defense_tower_c", {})).get("vp", 0)) == 3, "Defense tower C should be worth 3 VP.")
	_require(String(Dictionary(catalog.get("punishment_tower_f", {})).get("spawn_relation", "")) == "midfield", "Punishment tower F should be a midfield Star Soul.")
	_require(String(Dictionary(catalog.get("coward_a", {})).get("movement", "")) == "flee_from_any_unit", "Coward should flee from nearby units.")

	var draft := [
		{"player": 2, "star_soul_id": "defense_tower_a"},
		{"player": 1, "star_soul_id": "punishment_tower_a"},
		{"player": 2, "star_soul_id": "cart_a"},
		{"player": 1, "star_soul_id": "wandering_giant_a"},
		{"player": 2, "star_soul_id": "coward_a"},
		{"player": 1, "star_soul_id": "loyalist_a"},
	]
	var validation: Dictionary = service.validate_draft(draft, 2, 3, catalog.keys())
	_require(bool(validation.get("valid", false)), "Expected valid shared-pool draft: %s" % str(validation))

	var duplicate_draft := draft.duplicate(true)
	duplicate_draft[3]["star_soul_id"] = "cart_a"
	var duplicate_validation: Dictionary = service.validate_draft(duplicate_draft, 2, 3, catalog.keys())
	_require(not bool(duplicate_validation.get("valid", true)), "Shared-pool duplicate picks should be rejected.")
	_require(Array(duplicate_validation.get("errors", [])).has("pick_3_duplicate_star_soul"), "Duplicate error should name the duplicate turn: %s" % str(duplicate_validation))

	var wrong_turn_draft := draft.duplicate(true)
	wrong_turn_draft[0]["player"] = 1
	var wrong_turn_validation: Dictionary = service.validate_draft(wrong_turn_draft, 2, 3, catalog.keys())
	_require(Array(wrong_turn_validation.get("errors", [])).has("pick_0_wrong_player"), "Wrong BP turn order should be rejected.")

	var queue_result: Dictionary = service.build_spawn_queue(draft, 2, 3, {
		"pool_ids": catalog.keys(),
		"announce_seconds": 10.0,
		"per_player_order": {
			2: ["coward_a", "defense_tower_a", "cart_a"],
			1: ["loyalist_a", "punishment_tower_a", "wandering_giant_a"],
		},
	})
	_require(bool(queue_result.get("valid", false)), "Expected valid spawn queue: %s" % str(queue_result))
	var queue: Array = queue_result.get("queue", [])
	_require(_owners(queue) == [2, 1, 2, 1, 2, 1], "Spawn queue should alternate owners from BP first player: %s" % str(queue))
	_require(_star_soul_ids(queue) == ["coward_a", "loyalist_a", "defense_tower_a", "punishment_tower_a", "cart_a", "wandering_giant_a"], "Per-player order override should change internal order only: %s" % str(queue))
	var announcement: Dictionary = service.next_announcement(queue, 0)
	_require(String(announcement.get("action", "")) == "announce", "Next queue entry should announce before spawn.")
	_require(is_equal_approx(float(announcement.get("countdown", 0.0)), 10.0), "Announcement countdown should default to ten seconds.")

	var destroyed_award: Dictionary = service.vp_award_for_exit(2, 3, "destroyed")
	_require(bool(destroyed_award.get("award", false)), "Destroyed opposing Star Soul should award VP.")
	_require(int(destroyed_award.get("player", 0)) == 1, "Opponent of owner should receive VP.")
	_require(int(destroyed_award.get("vp", 0)) == 3, "Award should preserve Star Soul VP value.")
	var timeout_award: Dictionary = service.vp_award_for_exit(2, 3, "timeout")
	_require(not bool(timeout_award.get("award", true)), "Timeout should not award kill VP.")

	var design := FileAccess.get_file_as_string(ProjectSettings.globalize_path(DESIGN_PATH))
	for token in ["两个玩家画面宽度", "1.5 个玩家画面高度", "同一时间场上只存在一个星魂", "10 秒", "VP", "公共星魂池"]:
		_require(design.find(token) >= 0, "Design document missing token: %s" % token)

	if failed:
		quit(1)
		return
	print("STAR_SOUL_BP_SERVICE_PROBE ok queue=%s" % str(_star_soul_ids(queue)))
	quit(0)


func _players(turns: Array) -> Array:
	var result: Array = []
	for raw_turn in turns:
		if raw_turn is Dictionary:
			result.append(int(Dictionary(raw_turn).get("player", 0)))
	return result


func _owners(queue: Array) -> Array:
	var result: Array = []
	for raw_entry in queue:
		if raw_entry is Dictionary:
			result.append(int(Dictionary(raw_entry).get("owner", 0)))
	return result


func _star_soul_ids(queue: Array) -> Array:
	var result: Array = []
	for raw_entry in queue:
		if raw_entry is Dictionary:
			result.append(String(Dictionary(raw_entry).get("star_soul_id", "")))
	return result


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
