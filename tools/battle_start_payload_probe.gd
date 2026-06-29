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
		"BATTLE_START_PAYLOAD_SCHEMA_VERSION",
		"func battle_start_payload",
		"func serialize_battle_start_payload",
		"func deserialize_battle_start_payload",
		"remote_input_slots",
		"replay_seed",
		"simulation_hz",
	]:
		if not service_source.contains(token):
			_fail("BattleInputService missing battle-start payload token: %s" % token)
	if not failures.is_empty():
		_finish()
		return

	var service = BattleInputServiceScript.new()
	var action_names := ["p2_attack_1", "p1_left", "p1_left", "battle_pause", "p2_down"]
	var remote_slots_a := [
		{"player_id": 2, "prefix": "p2", "source": "remote", "slot_id": "remote-p2"},
		{"player_id": 1, "prefix": "p1", "source": "local", "slot_id": "local-p1"},
	]
	var remote_slots_b := [
		{"source": "local", "slot_id": "local-p1", "prefix": "p1", "player_id": 1},
		{"source": "remote", "slot_id": "remote-p2", "prefix": "p2", "player_id": 2},
	]
	var payload_a: Dictionary = service.battle_start_payload(" pvp ", 1, 12345, action_names, {
		"simulation_hz": 120,
		"remote_input_slots": remote_slots_a,
	})
	var payload_b: Dictionary = service.battle_start_payload("pvp", 1, 12345, action_names.duplicate(true), {
		"remote_input_slots": remote_slots_b,
		"simulation_hz": 120,
	})
	if not _expect(String(payload_a.get("mode", "")) == "pvp" and int(payload_a.get("ai_seat", 0)) == 1, "Battle-start payload should normalize mode and seat: %s" % str(payload_a)):
		_finish()
		return
	if not _expect(int(payload_a.get("replay_seed", 0)) == 12345 and int(payload_a.get("simulation_hz", 0)) == 120, "Battle-start payload should preserve replay seed and simulation hz: %s" % str(payload_a)):
		_finish()
		return
	if not _expect(Array(payload_a.get("action_names", [])) == ["battle_pause", "p1_left", "p2_attack_1", "p2_down"], "Battle-start payload should sort/dedupe action names: %s" % str(payload_a)):
		_finish()
		return
	var route: Dictionary = Dictionary(payload_a.get("control_route", {}))
	var routes: Array = Array(route.get("routes", []))
	if not _expect(String(route.get("action", "")) == "players" and routes.size() == 2 and int(Dictionary(routes[0]).get("player_id", 0)) == 1 and String(Dictionary(routes[1]).get("prefix", "")) == "p2", "PVP battle-start payload should preserve local two-player route: %s" % str(route)):
		_finish()
		return
	var remote_slots: Array = Array(payload_a.get("remote_input_slots", []))
	if not _expect(remote_slots.size() == 2 and int(Dictionary(remote_slots[0]).get("player_id", 0)) == 1 and String(Dictionary(remote_slots[1]).get("slot_id", "")) == "remote-p2", "Battle-start payload should sort remote input slots: %s" % str(remote_slots)):
		_finish()
		return
	var serialized_a := service.serialize_battle_start_payload(payload_a)
	var serialized_b := service.serialize_battle_start_payload(payload_b)
	if not _expect(serialized_a == serialized_b, "Battle-start payload serialization should be stable for equivalent slot/action order: a=%s b=%s" % [serialized_a, serialized_b]):
		_finish()
		return
	var decoded: Dictionary = service.deserialize_battle_start_payload(serialized_a)
	if not _expect(decoded == payload_a, "Battle-start payload should survive JSON round trip: decoded=%s payload=%s" % [str(decoded), str(payload_a)]):
		_finish()
		return

	var spectator_payload: Dictionary = service.battle_start_payload("ai", 3, 7, ["p1_left"], {"simulation_hz": 60})
	var spectator_route: Dictionary = Dictionary(spectator_payload.get("control_route", {}))
	if not _expect(String(spectator_route.get("action", "")) == "spectator" and String(spectator_route.get("prefix", "")) == "p1" and int(spectator_payload.get("simulation_hz", 0)) == 60, "AI seat 3 battle-start payload should preserve spectator route and explicit tick rate: %s" % str(spectator_payload)):
		_finish()
		return
	var menu_payload: Dictionary = service.battle_start_payload("pvp", 1, 7, [], {"runtime_menu_visible": true})
	if not _expect(String(Dictionary(menu_payload.get("control_route", {})).get("action", "")) == "menu_open", "Battle-start payload should preserve runtime-menu gating: %s" % str(menu_payload)):
		_finish()
		return
	if not _expect(service.deserialize_battle_start_payload("not json").is_empty(), "Invalid battle-start payload JSON should decode empty."):
		_finish()
		return

	_finish()


func _finish() -> void:
	if not failures.is_empty():
		print("BATTLE_START_PAYLOAD_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("BATTLE_START_PAYLOAD_PROBE ok")
	quit(0)
