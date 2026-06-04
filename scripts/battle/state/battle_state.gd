extends RefCounted
class_name BattleState

const PHASE_IDLE := "idle"
const PHASE_SCOUT := "scout"
const PHASE_RUNNING := "running"
const PHASE_PRESERVED := "preserved"
const PHASE_CLEANUP := "cleanup"

var battle_mode_key := ""
var phase := PHASE_IDLE
var reset_count := 0
var preserve_count := 0
var cleanup_count := 0
var last_reason := ""
var last_payload := {}
var last_runtime_snapshot := {}
var last_cleanup_intent := {}


func begin_runtime(mode_key: String, reason: String = "", payload: Dictionary = {}) -> Dictionary:
	battle_mode_key = mode_key
	phase = PHASE_RUNNING
	reset_count += 1
	last_reason = reason
	last_payload = payload.duplicate(true)
	return snapshot()


func preserve_runtime(reason: String = "", payload: Dictionary = {}) -> Dictionary:
	phase = PHASE_PRESERVED
	preserve_count += 1
	last_reason = reason
	last_payload = payload.duplicate(true)
	return snapshot()


func record_runtime_snapshot(runtime_snapshot: Dictionary) -> Dictionary:
	last_runtime_snapshot = runtime_snapshot.duplicate(true)
	return last_runtime_snapshot.duplicate(true)


func record_cleanup_intent(cleanup_intent: Dictionary) -> Dictionary:
	last_cleanup_intent = cleanup_intent.duplicate(true)
	cleanup_count += 1
	if not bool(cleanup_intent.get("preserve", false)):
		phase = PHASE_CLEANUP
	return last_cleanup_intent.duplicate(true)


func snapshot() -> Dictionary:
	return {
		"battle_mode_key": battle_mode_key,
		"phase": phase,
		"reset_count": reset_count,
		"preserve_count": preserve_count,
		"cleanup_count": cleanup_count,
		"last_reason": last_reason,
		"last_payload": last_payload.duplicate(true),
		"last_runtime_snapshot": last_runtime_snapshot.duplicate(true),
		"last_cleanup_intent": last_cleanup_intent.duplicate(true),
	}


func reset() -> void:
	battle_mode_key = ""
	phase = PHASE_IDLE
	reset_count = 0
	preserve_count = 0
	cleanup_count = 0
	last_reason = ""
	last_payload = {}
	last_runtime_snapshot = {}
	last_cleanup_intent = {}
