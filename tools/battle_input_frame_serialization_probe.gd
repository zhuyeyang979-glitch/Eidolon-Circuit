extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_input_service.gd"
const BattleInputServiceScript := preload("res://scripts/services/battle_input_service.gd")

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"INPUT_FRAME_SCHEMA_VERSION",
		"func canonical_input_frame",
		"func serialize_input_frame",
		"func deserialize_input_frame",
		"func replay_input_frame_payload",
		"func serialize_replay_input_frame_payload",
		"func deserialize_replay_input_frame_payload",
	]:
		if not service_source.contains(token):
			_fail("BattleInputService missing input-frame serialization token: %s" % token)
	if not failures.is_empty():
		_finish()
		return

	var service = BattleInputServiceScript.new()
	var action_names: Array = service.battle_action_names(["p1", "p2"], 2)
	var frame_a := {
		"pressed": {
			"p2_attack_1": true,
			"unregistered_debug_action": true,
			"p1_left": true,
			"p1_attack_3": true,
			"p2_right": false,
		},
		"released": {
			"p2_down": true,
			"p1_portal": true,
		},
	}
	var frame_b := {
		"released": {
			"p1_portal": true,
			"p2_down": true,
		},
		"pressed": {
			"p1_attack_3": true,
			"p1_left": true,
			"p2_attack_1": true,
			"unregistered_debug_action": true,
		},
	}
	var canonical: Dictionary = service.canonical_input_frame(frame_a, action_names)
	if not _expect(Array(canonical.get("pressed", [])) == ["p1_left", "p2_attack_1"], "Canonical frame should sort, filter, and omit false edges: %s" % str(canonical)):
		_finish()
		return
	if not _expect(Array(canonical.get("released", [])) == ["p1_portal", "p2_down"], "Canonical frame should sort released edges: %s" % str(canonical)):
		_finish()
		return
	var serialized_a := service.serialize_input_frame(frame_a, action_names)
	var serialized_b := service.serialize_input_frame(frame_b, action_names)
	if not _expect(serialized_a == serialized_b, "Input-frame serialization should ignore Dictionary insertion order: a=%s b=%s" % [serialized_a, serialized_b]):
		_finish()
		return

	var restored_frame: Dictionary = service.deserialize_input_frame(serialized_a)
	var consumed: Dictionary = service.consume_edges_once(restored_frame, true)
	if not _expect(service.action_just_pressed("p1_left", consumed, Callable(self, "_never_for_probe")), "Restored frame should feed action_just_pressed."):
		_finish()
		return
	if not _expect(service.action_just_released("p2_down", consumed, Callable(self, "_never_for_probe")), "Restored frame should feed action_just_released."):
		_finish()
		return
	if not _expect(service.deserialize_input_frame("not json") == {"pressed": {}, "released": {}}, "Invalid serialized input frames should decode to an empty edge frame."):
		_finish()
		return

	var pvp_payload_a: Dictionary = service.replay_input_frame_payload(" pvp ", 1, false, frame_a, action_names)
	var pvp_payload_b: Dictionary = service.replay_input_frame_payload("pvp", 1, false, frame_b, action_names)
	var pvp_json_a := service.serialize_replay_input_frame_payload(pvp_payload_a)
	var pvp_json_b := service.serialize_replay_input_frame_payload(pvp_payload_b)
	if not _expect(pvp_json_a == pvp_json_b, "Replay payload serialization should be stable for equivalent PVP input frames: a=%s b=%s" % [pvp_json_a, pvp_json_b]):
		_finish()
		return
	var decoded_pvp: Dictionary = service.deserialize_replay_input_frame_payload(pvp_json_a)
	var decoded_route: Dictionary = Dictionary(decoded_pvp.get("control_route", {}))
	if not _expect(String(decoded_route.get("action", "")) == "players", "Decoded PVP payload should preserve players route: %s" % str(decoded_pvp)):
		_finish()
		return
	var routes: Array = Array(decoded_route.get("routes", []))
	if not _expect(routes.size() == 2 and int(Dictionary(routes[0]).get("player_id", 0)) == 1 and String(Dictionary(routes[0]).get("prefix", "")) == "p1" and int(Dictionary(routes[1]).get("player_id", 0)) == 2 and String(Dictionary(routes[1]).get("prefix", "")) == "p2", "Decoded PVP payload should preserve seat-to-player prefixes: %s" % str(decoded_route)):
		_finish()
		return
	if not _expect(Array(Dictionary(decoded_pvp.get("input_frame", {})).get("pressed", [])) == ["p1_left", "p2_attack_1"], "Decoded PVP payload should preserve canonical frame: %s" % str(decoded_pvp)):
		_finish()
		return

	var spectator_payload: Dictionary = service.replay_input_frame_payload("ai", 3, false, frame_a, action_names)
	var spectator_route: Dictionary = Dictionary(spectator_payload.get("control_route", {}))
	if not _expect(String(spectator_route.get("action", "")) == "spectator" and String(spectator_route.get("prefix", "")) == "p1", "AI seat 3 replay payload should preserve spectator route: %s" % str(spectator_payload)):
		_finish()
		return
	var menu_payload: Dictionary = service.replay_input_frame_payload("pvp", 1, true, frame_a, action_names)
	if not _expect(String(Dictionary(menu_payload.get("control_route", {})).get("action", "")) == "menu_open", "Replay payload should preserve runtime-menu route gating: %s" % str(menu_payload)):
		_finish()
		return

	_finish()


func _never_for_probe(_action_name: String) -> bool:
	return false


func _finish() -> void:
	if not failures.is_empty():
		print("BATTLE_INPUT_FRAME_SERIALIZATION_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("BATTLE_INPUT_FRAME_SERIALIZATION_PROBE ok")
	quit(0)
