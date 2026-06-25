extends SceneTree

const BP_SERVICE_PATH := "res://scripts/services/star_soul_bp_service.gd"
const RUNTIME_SERVICE_PATH := "res://scripts/services/star_soul_runtime_queue_service.gd"

var failed := false


func _init() -> void:
	_require(FileAccess.file_exists(BP_SERVICE_PATH), "Missing StarSoulBPService script.")
	_require(FileAccess.file_exists(RUNTIME_SERVICE_PATH), "Missing StarSoulRuntimeQueueService script.")
	if failed:
		quit(1)
		return
	var BPServiceScript = load(BP_SERVICE_PATH)
	var RuntimeServiceScript = load(RUNTIME_SERVICE_PATH)
	_require(BPServiceScript != null, "Cannot load StarSoulBPService.")
	_require(RuntimeServiceScript != null, "Cannot load StarSoulRuntimeQueueService.")
	if failed:
		quit(1)
		return
	var bp_service = BPServiceScript.new()
	var runtime_service = RuntimeServiceScript.new()
	var catalog: Dictionary = bp_service.catalog_by_id()
	var draft := [
		{"player": 2, "star_soul_id": "defense_tower_c"},
		{"player": 1, "star_soul_id": "punishment_tower_a"},
		{"player": 2, "star_soul_id": "cart_a"},
		{"player": 1, "star_soul_id": "wandering_giant_a"},
	]
	var payload: Dictionary = bp_service.build_spawn_queue(draft, 2, 2, {"pool_ids": catalog.keys(), "announce_seconds": 10.0})
	_require(bool(payload.get("valid", false)), "Draft payload should be valid.")

	var state: Dictionary = runtime_service.initial_state(payload, catalog, {"replay_seed": 42})
	_require(String(state.get("phase", "")) == "announcing", "Runtime should start by announcing the first Star Soul.")
	_require(int(state.get("replay_seed", 0)) == 42, "Runtime state should preserve deterministic replay seed.")
	_require(String(Dictionary(state.get("pending_entry", {})).get("star_soul_id", "")) == "defense_tower_c", "First pending Star Soul should belong to BP first player.")
	_require(is_equal_approx(float(state.get("countdown", 0.0)), 10.0), "Announcement countdown should start at 10 seconds.")

	var early_tick: Dictionary = runtime_service.tick(state, 4.0)
	state = early_tick.get("state", {})
	_require(String(early_tick.get("reason", "")) == "announce_tick", "Early tick should keep announcing.")
	_require(is_equal_approx(float(state.get("countdown", 0.0)), 6.0), "Countdown should decrease while announcing.")
	_require(not state.has("spawn_intent"), "No spawn intent should exist before countdown ends.")

	var ready_tick: Dictionary = runtime_service.tick(state, 6.0)
	state = ready_tick.get("state", {})
	_require(String(state.get("phase", "")) == "spawn_ready", "Countdown end should make spawn ready.")
	var spawn_intent: Dictionary = Dictionary(state.get("spawn_intent", {}))
	_require(String(spawn_intent.get("action", "")) == "spawn_star_soul", "Spawn-ready state should expose spawn intent.")
	_require(String(spawn_intent.get("star_soul_id", "")) == "defense_tower_c", "Spawn intent should name the pending Star Soul.")
	_require(int(spawn_intent.get("vp", 0)) == 3, "Spawn intent should include catalog VP value.")

	var repeated_ready: Dictionary = runtime_service.tick(state, 2.0)
	_require(String(repeated_ready.get("reason", "")) == "tick", "Ticking spawn-ready state should not emit a second countdown transition.")
	var committed: Dictionary = runtime_service.spawn_committed(state, "runtime_a")
	_require(bool(committed.get("changed", false)), "Spawn commit should be accepted.")
	state = committed.get("state", {})
	_require(String(state.get("phase", "")) == "active", "Committed Star Soul should become active.")
	_require(String(Dictionary(state.get("active_entry", {})).get("runtime_id", "")) == "runtime_a", "Active entry should preserve runtime id.")
	_require(not state.has("spawn_intent"), "Active state should clear spawn intent.")

	var blocked_second_spawn: Dictionary = runtime_service.spawn_committed(state, "runtime_b")
	_require(not bool(blocked_second_spawn.get("changed", true)), "Runtime should reject spawning while one Star Soul is active.")
	_require(String(blocked_second_spawn.get("reason", "")) == "no_spawn_ready", "Blocked second spawn should be explicit.")
	var active_tick: Dictionary = runtime_service.tick(state, 10.0)
	_require(String(Dictionary(active_tick.get("state", {})).get("phase", "")) == "active", "Ticking active state should not spawn a second Star Soul.")

	var destroyed: Dictionary = runtime_service.active_exit(state, "destroyed", "runtime_a")
	_require(bool(destroyed.get("changed", false)), "Destroyed active Star Soul should advance runtime.")
	state = destroyed.get("state", {})
	_require(int(Dictionary(state.get("vp_by_player", {})).get(1, 0)) == 3, "Opponent of owner should gain VP on destroy.")
	_require(String(state.get("phase", "")) == "announcing", "Runtime should announce the next Star Soul after active exit.")
	_require(String(Dictionary(state.get("pending_entry", {})).get("star_soul_id", "")) == "punishment_tower_a", "Next queue entry should be pending.")
	_require(Array(state.get("history", [])).size() == 1, "Destroyed Star Soul should be written to history.")

	state = runtime_service.tick(state, 10.0).get("state", {})
	state = runtime_service.spawn_committed(state, "runtime_b").get("state", {})
	var timeout_exit: Dictionary = runtime_service.active_exit(state, "timeout", "runtime_b")
	state = timeout_exit.get("state", {})
	_require(int(Dictionary(state.get("vp_by_player", {})).get(2, 0)) == 0, "Timeout should not award kill VP.")
	_require(Array(state.get("history", [])).size() == 2, "Timeout exit should still be recorded in history.")

	state = _spawn_and_exit(runtime_service, state, "runtime_c", "arrival")
	state = _spawn_and_exit(runtime_service, state, "runtime_d", "destroyed")
	_require(String(state.get("phase", "")) == "complete", "Runtime should complete after final queue entry exits.")
	_require(String(runtime_service.current_announcement(state).get("action", "")) == "none", "Complete runtime should have no announcement.")

	if failed:
		quit(1)
		return
	print("STAR_SOUL_RUNTIME_QUEUE_SERVICE_PROBE ok vp=%s history=%d" % [str(state.get("vp_by_player", {})), Array(state.get("history", [])).size()])
	quit(0)


func _spawn_and_exit(runtime_service, state: Dictionary, runtime_id: String, reason: String) -> Dictionary:
	var next_state: Dictionary = runtime_service.tick(state, 10.0).get("state", {})
	next_state = runtime_service.spawn_committed(next_state, runtime_id).get("state", {})
	return runtime_service.active_exit(next_state, reason, runtime_id).get("state", {})


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
