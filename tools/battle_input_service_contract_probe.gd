extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_input_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleInputServiceScript := preload("res://scripts/services/battle_input_service.gd")

var pressed_actions := {}
var released_actions := {}
var action_strengths := {}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing BattleInputService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name BattleInputService",
		"battle_action_names",
		"capture_edge_frame",
		"capture_input_frame",
		"consume_edges_once",
		"canonical_input_frame",
		"input_frame_from_canonical",
		"serialize_input_frame",
		"deserialize_input_frame",
		"replay_input_frame_payload",
		"serialize_replay_input_frame_payload",
		"deserialize_replay_input_frame_payload",
		"battle_start_payload",
		"serialize_battle_start_payload",
		"deserialize_battle_start_payload",
		"replay_checkpoint",
		"replay_checkpoint_digest",
		"first_replay_desync",
		"action_just_pressed",
		"action_just_released",
		"action_pressed",
		"action_strength",
		"battle_control_routes",
		"direction_just_pressed",
		"movement_input_state",
		"input_vector_from_strengths",
		"gun_turn_input_vector_from_strengths",
		"spectator_input_intent",
	]:
		if service_source.find(token) < 0:
			_fail("BattleInputService missing token: %s" % token)
			return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "Button", "extends Control", "Control.new", "_begin_battle", "_summon_role", "_toggle_battle_runtime_menu", "active_units"]:
		if service_source.find(forbidden) >= 0:
			_fail("BattleInputService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattleInputService = preload(\"res://scripts/services/battle_input_service.gd\")",
		"var battle_input_service: BattleInputService",
		"battle_input_service = BattleInputService.new()",
		"func _battle_input_service() -> BattleInputService",
		"_battle_input_service().battle_action_names",
		"_battle_input_service().capture_input_frame",
		"_battle_input_service().consume_edges_once",
		"_battle_input_service().action_just_pressed",
		"_battle_input_service().action_just_released",
		"_battle_input_service().action_pressed",
		"_battle_input_service().action_strength",
		"_battle_input_service().battle_control_routes",
		"_battle_input_service().direction_just_pressed",
		"_battle_input_service().movement_input_state",
		"_battle_input_service().input_vector_from_strengths",
		"_battle_input_service().gun_turn_input_vector_from_strengths",
		"_battle_input_service().spectator_input_intent",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate battle input service token: %s" % token)
			return
	for forbidden in [
		"battle_input_service.battle_",
		"battle_input_service.capture_edge_frame",
		"battle_input_service.capture_input_frame",
		"battle_input_service.consume_edges_once",
		"battle_input_service.action_just_",
		"battle_input_service.direction_just_pressed",
		"battle_input_service.movement_input_state",
		"battle_input_service.spectator_input_intent",
		"battle_input_service.input_vector_from_strengths",
		"battle_input_service.gun_turn_input_vector_from_strengths",
		"battle_input_service != null",
		"_legacy_battle_control_routes",
		"_legacy_spectator_input_intent",
		"_legacy_movement_input_state",
	]:
		if main_source.find(forbidden) >= 0:
			_fail("main.gd should not keep legacy BattleInputService fallback token: %s" % forbidden)
			return
	var service = BattleInputServiceScript.new()
	var actions: Array = service.battle_action_names(["p1", "p2"], 6)
	for action_name in ["battle_pause", "p1_left", "p1_right", "p1_up", "p1_down", "p1_face_left", "p1_face_right", "p1_cool", "p1_portal", "p1_attack_6", "p2_cool", "p2_attack_6"]:
		if not actions.has(action_name):
			_fail("battle_action_names missing action: %s in %s" % [action_name, str(actions)])
			return
	if actions.has("p1_attack_7"):
		_fail("battle_action_names should honor attack group count.")
		return
	pressed_actions = {"p1_left": true}
	released_actions = {"p1_attack_1": true}
	var edge_frame: Dictionary = service.capture_edge_frame(
		["p1_left", "p1_right", "p1_attack_1", "p1_attack_2"],
		{"battle_pause": true},
		{"p1_portal": true},
		Callable(self, "_pressed_for_probe"),
		Callable(self, "_released_for_probe")
	)
	if not bool(Dictionary(edge_frame.get("pressed", {})).get("battle_pause", false)) or not bool(Dictionary(edge_frame.get("pressed", {})).get("p1_left", false)):
		_fail("capture_edge_frame should merge pending and sampled just-pressed edges: %s" % str(edge_frame))
		return
	if not bool(Dictionary(edge_frame.get("released", {})).get("p1_portal", false)) or not bool(Dictionary(edge_frame.get("released", {})).get("p1_attack_1", false)):
		_fail("capture_edge_frame should merge pending and sampled just-released edges: %s" % str(edge_frame))
		return
	action_strengths = {"p1_right": 0.75, "p1_attack_2": 1.0}
	var input_frame: Dictionary = service.capture_input_frame(
		["p1_left", "p1_right", "p1_attack_1", "p1_attack_2"],
		{},
		{},
		Callable(self, "_pressed_for_probe"),
		Callable(self, "_released_for_probe"),
		Callable(self, "_strength_for_probe")
	)
	if not is_equal_approx(float(Dictionary(input_frame.get("strengths", {})).get("p1_right", 0.0)), 0.75):
		_fail("capture_input_frame should preserve sampled analog strengths: %s" % str(input_frame))
		return
	var consumed: Dictionary = service.consume_edges_once(edge_frame, true)
	if not bool(consumed.get("frame_active", false)) or not bool(consumed.get("edges_enabled", false)) or not bool(consumed.get("clear_pending_edges", false)):
		_fail("consume_edges_once should activate and clear consumed edge frames: %s" % str(consumed))
		return
	if not bool(service.action_just_pressed("p1_left", consumed, Callable(self, "_never_for_probe"))):
		_fail("action_just_pressed should read active consumed frame edges.")
		return
	var muted: Dictionary = service.consume_edges_once(edge_frame, false)
	if bool(service.action_just_pressed("p1_left", muted, Callable(self, "_always_for_probe"))):
		_fail("action_just_pressed should ignore edges after first substep.")
		return
	if not bool(service.action_just_released("p1_attack_1", consumed, Callable(self, "_never_for_probe"))):
		_fail("action_just_released should read active consumed frame edges.")
		return
	if not bool(service.action_just_pressed("fallback", {"frame_active": false}, Callable(self, "_always_for_probe"))):
		_fail("action_just_pressed should fall back when no frame is active.")
		return
	if bool(service.action_just_released("fallback", {"frame_active": false}, Callable(self, "_never_for_probe"))):
		_fail("action_just_released should respect fallback false.")
		return
	var held_consumed: Dictionary = service.consume_edges_once(input_frame, false)
	if not service.action_pressed("p1_right", held_consumed, Callable(self, "_never_for_probe")):
		_fail("action_pressed should preserve held input after edge consumption.")
		return
	if not is_equal_approx(service.action_strength("p1_right", held_consumed, Callable(self, "_zero_strength_for_probe")), 0.75):
		_fail("action_strength should preserve analog input after edge consumption.")
		return
	_assert_route(service.battle_control_routes("ai", 1, false), {"action": "players", "routes": [{"player_id": 1, "prefix": "p1"}]})
	_assert_route(service.battle_control_routes("ai", 2, false), {"action": "players", "routes": [{"player_id": 2, "prefix": "p1"}]})
	_assert_route(service.battle_control_routes("ai", 3, false), {"action": "spectator", "prefix": "p1"})
	_assert_route(service.battle_control_routes("pvp", 1, false), {"action": "players", "routes": [{"player_id": 1, "prefix": "p1"}, {"player_id": 2, "prefix": "p2"}]})
	_assert_route(service.battle_control_routes("training", 1, false), {"action": "players", "routes": [{"player_id": 1, "prefix": "p1"}]})
	_assert_route(service.battle_control_routes("training", 2, false), {"action": "players", "routes": [{"player_id": 2, "prefix": "p1"}]})
	_assert_route(service.battle_control_routes("training", 3, false), {"action": "spectator", "prefix": "p1"})
	_assert_route(service.battle_control_routes("training", 1, true), {"action": "menu_open"})
	pressed_actions = {"p1_right": true}
	if not service.direction_just_pressed("p1", Callable(self, "_pressed_for_probe")):
		_fail("direction_just_pressed should report directional edges.")
		return
	pressed_actions = {}
	if service.direction_just_pressed("p1", Callable(self, "_pressed_for_probe")):
		_fail("direction_just_pressed should ignore missing directional edges.")
		return
	var move_start: Dictionary = service.movement_input_state(Vector2(0.5, 0.0), Vector2.ZERO, false)
	if not bool(move_start.get("has_move_input", false)) or not bool(move_start.get("movement_just_pressed", false)):
		_fail("movement_input_state should mark fresh movement input.")
		return
	var move_hold: Dictionary = service.movement_input_state(Vector2(0.5, 0.0), Vector2(0.4, 0.0), false)
	if bool(move_hold.get("movement_just_pressed", true)):
		_fail("movement_input_state should not mark held movement without a direction edge.")
		return
	var move_tap: Dictionary = service.movement_input_state(Vector2(0.5, 0.0), Vector2(0.4, 0.0), true)
	if not bool(move_tap.get("movement_just_pressed", false)):
		_fail("movement_input_state should mark direction tap edges.")
		return
	var move_idle: Dictionary = service.movement_input_state(Vector2(0.01, 0.0), Vector2.ZERO, true)
	if bool(move_idle.get("has_move_input", true)) or bool(move_idle.get("movement_just_pressed", true)):
		_fail("movement_input_state should ignore tiny vectors.")
		return
	if service.input_vector_from_strengths(0.04, 0.0, 0.0, 0.0) != Vector2.ZERO:
		_fail("input_vector_from_strengths should apply the movement deadzone.")
		return
	var diagonal_input: Vector2 = service.input_vector_from_strengths(1.0, 0.0, 1.0, 0.0)
	if absf(diagonal_input.length() - 1.0) > 0.001 or diagonal_input.x <= 0.7 or diagonal_input.y <= 0.7:
		_fail("input_vector_from_strengths should normalize over-length diagonals: %s" % str(diagonal_input))
		return
	var analog_input: Vector2 = service.input_vector_from_strengths(0.6, 0.1, 0.2, 0.0)
	if analog_input.distance_to(Vector2(0.5, 0.2)) > 0.001:
		_fail("input_vector_from_strengths should preserve analog vectors inside unit length: %s" % str(analog_input))
		return
	if service.gun_turn_input_vector_from_strengths(0.05, 0.0) != Vector2.ZERO:
		_fail("gun_turn_input_vector_from_strengths should apply turn deadzone.")
		return
	if service.gun_turn_input_vector_from_strengths(1.4, 0.0) != Vector2(1.0, 0.0) or service.gun_turn_input_vector_from_strengths(0.0, 1.4) != Vector2(-1.0, 0.0):
		_fail("gun_turn_input_vector_from_strengths should clamp turn input.")
		return
	pressed_actions = {"p1_face_left": true, "p1_attack_3": true}
	var spectator: Dictionary = service.spectator_input_intent("p1", Vector2(0.4, -0.3), Callable(self, "_pressed_for_probe"))
	if not bool(spectator.get("free_pan", false)) or int(spectator.get("cycle", 0)) != -1 or String(spectator.get("view_mode", "")) != "mid":
		_fail("spectator_input_intent should classify pan, cycle, and view mode: %s" % str(spectator))
		return
	pressed_actions = {"p1_attack_4": true}
	var spectator_free: Dictionary = service.spectator_input_intent("p1", Vector2.ZERO, Callable(self, "_pressed_for_probe"))
	if bool(spectator_free.get("free_pan", true)) or String(spectator_free.get("view_mode", "")) != "free":
		_fail("spectator_input_intent should classify free camera shortcut: %s" % str(spectator_free))
		return
	print("BATTLE_INPUT_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _assert_route(actual: Dictionary, expected: Dictionary) -> void:
	for key in expected.keys():
		if actual.get(key) != expected[key]:
			_fail("Expected route %s=%s, got %s in %s." % [String(key), str(expected[key]), str(actual.get(key)), str(actual)])


func _pressed_for_probe(action_name: String) -> bool:
	return bool(pressed_actions.get(action_name, false))


func _released_for_probe(action_name: String) -> bool:
	return bool(released_actions.get(action_name, false))


func _strength_for_probe(action_name: String) -> float:
	return float(action_strengths.get(action_name, 0.0))


func _zero_strength_for_probe(_action_name: String) -> float:
	return 0.0


func _always_for_probe(_action_name: String) -> bool:
	return true


func _never_for_probe(_action_name: String) -> bool:
	return false
