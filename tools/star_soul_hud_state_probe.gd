extends SceneTree

const BPService := preload("res://scripts/services/star_soul_bp_service.gd")
const RuntimeService := preload("res://scripts/services/star_soul_runtime_queue_service.gd")
const HudService := preload("res://scripts/services/battle_hud_state_service.gd")
const MainScene := preload("res://scripts/main.gd")

var failed := false


func _init() -> void:
	var bp_service = BPService.new()
	var runtime_service = RuntimeService.new()
	var hud_service = HudService.new()
	var catalog: Dictionary = bp_service.catalog_by_id()
	var payload: Dictionary = bp_service.build_spawn_queue([
		{"player": 1, "star_soul_id": "defense_tower_c"},
		{"player": 2, "star_soul_id": "punishment_tower_a"},
	], 1, 1, {"pool_ids": catalog.keys(), "announce_seconds": 10.0})
	_require(bool(payload.get("valid", false)), "Draft payload should be valid.")
	var terms := {
		"star_soul": "SOUL",
		"in": "IN",
		"ready": "READY",
		"active": "ACTIVE",
		"complete": "DONE",
		"score": "SCORE",
		"tied": "TIED",
		"leads": "LEADS",
		"match_point": "MATCH POINT",
		"victory_points": "VP",
		"resource": "RES",
		"portal": "PORT",
	}
	var state: Dictionary = runtime_service.initial_state(payload, catalog)
	var announcing: Dictionary = hud_service.star_soul_hud_model(state, terms)
	_require(bool(announcing.get("visible", false)), "Announcing Star Soul model should be visible.")
	_require(String(announcing.get("text", "")) == "SOUL P1 defense_tower_c +3 IN 10s", "Announcing text mismatch: %s" % str(announcing))
	_require(int(announcing.get("p1_vp", -1)) == 0 and int(announcing.get("p2_vp", -1)) == 0, "Initial Star Soul VP display should be 0-0.")

	state = runtime_service.tick(state, 10.0).get("state", {})
	var ready: Dictionary = hud_service.star_soul_hud_model(state, terms)
	_require(String(ready.get("text", "")) == "SOUL P1 defense_tower_c +3 READY", "Spawn-ready text mismatch: %s" % str(ready))
	state = runtime_service.spawn_committed(state, "runtime_star_soul_1").get("state", {})
	var active: Dictionary = hud_service.star_soul_hud_model(state, terms)
	_require(String(active.get("text", "")) == "SOUL P1 defense_tower_c +3 ACTIVE", "Active text mismatch: %s" % str(active))

	state = runtime_service.active_exit(state, "destroyed", "runtime_star_soul_1").get("state", {})
	var next_announcement: Dictionary = hud_service.star_soul_hud_model(state, terms)
	_require(String(next_announcement.get("text", "")) == "SOUL P2 punishment_tower_a +1 IN 10s", "Next announcement text mismatch: %s" % str(next_announcement))
	_require(int(next_announcement.get("p2_vp", -1)) == 3, "Destroying P1 Star Soul should award P2 VP in HUD model.")
	_require(int(next_announcement.get("history_count", 0)) == 1, "HUD model should expose Star Soul history count.")

	state = runtime_service.tick(state, 10.0).get("state", {})
	state = runtime_service.spawn_committed(state, "runtime_star_soul_2").get("state", {})
	state = runtime_service.active_exit(state, "timeout", "runtime_star_soul_2").get("state", {})
	var complete: Dictionary = hud_service.star_soul_hud_model(state, terms)
	_require(String(complete.get("text", "")) == "SOUL DONE  P1 0 - 3 P2", "Complete text mismatch: %s" % str(complete))

	var heavy_model: Dictionary = hud_service.heavy_hud_text_state({
		"terms": terms,
		"win_points": 5,
		"role_order": [],
		"players": {1: {"victory_points": 0}, 2: {"victory_points": 3}},
		"star_soul_runtime": state,
	})
	_require(heavy_model.has("star_soul"), "Heavy HUD text state should include Star Soul model when runtime state is present.")
	_require(String(Dictionary(heavy_model.get("star_soul", {})).get("text", "")) == "SOUL DONE  P1 0 - 3 P2", "Heavy HUD Star Soul text mismatch: %s" % str(heavy_model))
	var empty_model: Dictionary = hud_service.heavy_hud_text_state({"terms": terms, "win_points": 5, "role_order": [], "players": {}})
	_require(not bool(Dictionary(empty_model.get("star_soul", {})).get("visible", true)), "Heavy HUD text state should hide Star Soul UI when no runtime state exists.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in ["star_soul_label", "\"star_soul\": star_soul_label", "_battle_star_soul_runtime_snapshot", "battle_controller.star_soul_hud_snapshot", "_tick_star_soul_runtime", "clear_star_soul_runtime", "StarSoulStatus"]:
		_require(main_source.find(token) >= 0, "main.gd should wire Star Soul HUD token: %s" % token)
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var main_snapshot: Dictionary = main._battle_hud_text_snapshot()
	_require(not main_snapshot.has("star_soul_runtime"), "Fresh main HUD snapshot should not expose Star Soul runtime before the controller starts it.")

	if failed:
		quit(1)
		return
	print("STAR_SOUL_HUD_STATE_PROBE ok text=%s" % String(complete.get("text", "")))
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
