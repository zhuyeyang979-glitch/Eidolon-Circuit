extends RefCounted
class_name BattleMode

const BattleStateScript = preload("res://scripts/battle/state/battle_state.gd")

const MODE_KEY := "battle"
const TRAINING_MODE_KEY := "training"

var owner_root: Node
var battle_controller
var lifecycle_service
var state: RefCounted
var enter_count := 0
var exit_count := 0
var last_enter_context := {}
var last_exit_context := {}
var last_show_context := {}


func _init() -> void:
	state = BattleStateScript.new()


func bind(root_node: Node, controller, runtime_lifecycle_service = null) -> void:
	owner_root = root_node
	battle_controller = controller
	lifecycle_service = runtime_lifecycle_service


func is_bound() -> bool:
	return owner_root != null and battle_controller != null


func mode_key() -> String:
	return MODE_KEY


func normalized_battle_mode_key(battle_mode_key: String) -> String:
	return battle_mode_key.strip_edges()


func app_mode_key_for_battle_mode(battle_mode_key: String) -> String:
	return TRAINING_MODE_KEY if normalized_battle_mode_key(battle_mode_key) == TRAINING_MODE_KEY else MODE_KEY


func show_intent(battle_mode_key: String, preloaded: bool, loading_queued: bool, reason: String = "", preserve_runtime: bool = false) -> Dictionary:
	var resolved_battle_mode_key := normalized_battle_mode_key(battle_mode_key)
	var resolved_reason := reason.strip_edges()
	if resolved_reason == "":
		resolved_reason = "return_battle" if preserve_runtime else "battle:%s" % resolved_battle_mode_key
	return {
		"mode_key": app_mode_key_for_battle_mode(resolved_battle_mode_key),
		"battle_mode": resolved_battle_mode_key,
		"reason": resolved_reason,
		"payload": {"mode": resolved_battle_mode_key, "preserve_runtime": preserve_runtime} if preserve_runtime else {"mode": resolved_battle_mode_key},
		"preloaded": preloaded,
		"loading_queued": loading_queued,
		"should_apply": not loading_queued,
		"preserve_runtime": preserve_runtime,
		"reset_runtime": not preserve_runtime,
		"bound": is_bound(),
	}


func commit_show(intent: Dictionary) -> bool:
	if String(intent.get("battle_mode", "")) == "":
		return false
	last_show_context = intent.duplicate(true)
	var battle_mode_key := String(intent.get("battle_mode", ""))
	var reason := String(intent.get("reason", ""))
	var payload: Dictionary = Dictionary(intent.get("payload", {})).duplicate(true)
	if bool(intent.get("preserve_runtime", false)):
		state.preserve_runtime(reason, payload)
	elif bool(intent.get("reset_runtime", true)):
		state.begin_runtime(battle_mode_key, reason, payload)
	return true


func enter_intent(reason: String = "", payload: Dictionary = {}) -> Dictionary:
	var resolved_payload := payload.duplicate(true)
	if resolved_payload.has("mode"):
		resolved_payload["mode"] = normalized_battle_mode_key(String(resolved_payload.get("mode", "")))
	return {
		"mode_key": app_mode_key_for_battle_mode(String(resolved_payload.get("mode", ""))),
		"reason": reason,
		"payload": resolved_payload,
		"bound": is_bound(),
	}


func commit_enter(intent: Dictionary) -> bool:
	var intent_mode := String(intent.get("mode_key", ""))
	if intent_mode != MODE_KEY and intent_mode != TRAINING_MODE_KEY:
		return false
	enter_count += 1
	last_enter_context = intent.duplicate(true)
	return true


func runtime_snapshot(runtime_snapshot_value: Dictionary) -> Dictionary:
	return state.record_runtime_snapshot(runtime_snapshot_value)


func cleanup_intent(runtime_snapshot_value: Dictionary, preserve_for_return: bool = false) -> Dictionary:
	var snapshot_value: Dictionary = state.record_runtime_snapshot(runtime_snapshot_value)
	var intent: Dictionary
	if lifecycle_service != null:
		intent = lifecycle_service.cleanup_intent(snapshot_value, preserve_for_return)
	else:
		intent = _fallback_cleanup_intent(snapshot_value, preserve_for_return)
	intent["mode_key"] = app_mode_key_for_battle_mode(state.battle_mode_key)
	intent["battle_mode"] = state.battle_mode_key
	return intent


func commit_cleanup(intent: Dictionary) -> bool:
	if not bool(intent.get("preserve", false)) and not bool(intent.get("clear_runtime", false)):
		return false
	state.record_cleanup_intent(intent)
	return true


func exit_intent(reason: String = "", payload: Dictionary = {}) -> Dictionary:
	return {
		"mode_key": app_mode_key_for_battle_mode(state.battle_mode_key),
		"reason": reason,
		"payload": payload.duplicate(true),
		"bound": is_bound(),
	}


func commit_exit(intent: Dictionary) -> bool:
	var intent_mode := String(intent.get("mode_key", ""))
	if intent_mode != MODE_KEY and intent_mode != TRAINING_MODE_KEY:
		return false
	exit_count += 1
	last_exit_context = intent.duplicate(true)
	return true


func state_snapshot() -> Dictionary:
	return state.snapshot()


func _fallback_cleanup_intent(runtime_snapshot_value: Dictionary, preserve_for_return: bool) -> Dictionary:
	var summary := {
		"battle_runtime_count": max(0, int(runtime_snapshot_value.get("unit_count", 0))) \
			+ max(0, int(runtime_snapshot_value.get("pending_laser_shots", 0))) \
			+ max(0, int(runtime_snapshot_value.get("pending_true_bullet_shots", 0))) \
			+ max(0, int(runtime_snapshot_value.get("pending_chemical_projectiles", 0))) \
			+ max(0, int(runtime_snapshot_value.get("pending_missile_projectiles", 0))) \
			+ max(0, int(runtime_snapshot_value.get("active_web_tethers", 0))) \
			+ max(0, int(runtime_snapshot_value.get("active_web_swings", 0))),
		"battle_effect_children": max(0, int(runtime_snapshot_value.get("battle_effect_children", 0))),
	}
	if preserve_for_return:
		return {
			"preserve": true,
			"clear_runtime": false,
			"summary": summary,
			"categories": [],
			"reason": "preserve_for_return",
		}
	return {
		"preserve": false,
		"clear_runtime": true,
		"hide_runtime_menu": true,
		"hide_aim_lines": true,
		"clear_attack_command_windows": true,
		"clear_units": true,
		"clear_presentation_state": true,
		"clear_input_edges": true,
		"clear_aim_state": true,
		"clear_gun_state": true,
		"summary": summary,
		"categories": ["units", "effects", "pending_projectiles", "web_runtime", "aim_state", "input_edges", "gun_state"],
		"reason": "exit_battle",
	}
