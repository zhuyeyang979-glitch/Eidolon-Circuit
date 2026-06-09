extends SceneTree

const SERVICE_PATH := "res://scripts/services/held_melee_activation_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BOOT_PROFILE := "boot_action_driver"

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing HeldMeleeActivationService script.")
	else:
		var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
		for token in [
			"class_name HeldMeleeActivationService",
			"runtime_binding_is_held_melee_activation",
			"boot_driver_initial_state",
			"held_activation_state_payload",
			"turn_input_from_strengths",
			"tick_state_payload",
			"activation_state_active",
			"held_turn_keys_reserved",
			"should_release_hold",
			"held_activation_event_payload",
			"activation_direction",
		]:
			if service_source.find(token) < 0:
				_fail("HeldMeleeActivationService missing token: %s" % token)
		for forbidden in [
			"Input.",
			"FileAccess",
			"DirAccess",
			"JSON.parse_string",
			"extends Node",
			"extends Control",
			"active_units",
			"all_units",
			"held_melee_activation_state",
			"gun_activation_state",
			"begin_runtime_module_action",
			"_resolve_attack",
			"_show_battle_message",
			"FighterScene",
			"UnitScene",
		]:
			if service_source.find(forbidden) >= 0:
				_fail("HeldMeleeActivationService contains forbidden token: %s" % forbidden)
		var script = ResourceLoader.load(SERVICE_PATH)
		if script == null:
			_fail("Unable to load HeldMeleeActivationService.")
		else:
			var service = script.new()
			_assert(service.runtime_binding_is_held_melee_activation({"module_part": {"module_action_profile": BOOT_PROFILE}}, BOOT_PROFILE), "Module-part Boot Driver binding should classify as held melee activation.")
			_assert(not service.runtime_binding_is_held_melee_activation({"module_part": {"module_action_profile": BOOT_PROFILE}, "module_action_profile": "laser_beam_activate"}, BOOT_PROFILE), "Top-level profile should override module-part Boot Driver profile.")
			_assert(not service.runtime_binding_is_held_melee_activation({"module_action_profile": BOOT_PROFILE, "hold_to_activate": false}, BOOT_PROFILE), "Explicit false hold_to_activate should reject held melee activation.")
			_assert(not service.runtime_binding_is_held_melee_activation({"module_action_profile": "laser_beam_activate"}, BOOT_PROFILE), "Projectile activation should not classify as held melee activation.")
			_assert(service.boot_driver_initial_state(Vector2.ZERO, Vector2.RIGHT) == "normal", "Neutral input should start normal.")
			_assert(service.boot_driver_initial_state(Vector2.LEFT, Vector2.RIGHT) == "active", "Input opposite forward should start active.")
			_assert(service.boot_driver_initial_state(Vector2.RIGHT, Vector2.RIGHT) == "armor", "Input with forward should start armor.")
			_assert(service.boot_driver_initial_state(Vector2.UP, Vector2.RIGHT) == "normal", "Vertical input should start normal for right-facing unit.")
			_assert(service.boot_driver_initial_state(Vector2.RIGHT, Vector2.LEFT) == "active", "Input opposite left-facing forward should start active.")
			_assert(service.boot_driver_initial_state(Vector2.RIGHT, Vector2.ZERO) == "normal", "Missing forward vector should start normal.")
			var payload: Dictionary = service.held_activation_state_payload({
				"prefix": "p1_",
				"attack_index": 2,
				"action_name": "p1_attack_3",
				"binding": {"attack_key": 3, "module_part": {"turn_keys_steer_joint": false}},
				"profile": BOOT_PROFILE,
				"action_state": "active",
			})
			_assert(String(payload.get("prefix", "")) == "p1_" and int(payload.get("attack_index", -1)) == 2, "Held payload identity mismatch: %s" % str(payload))
			_assert(String(payload.get("module_action_profile", "")) == BOOT_PROFILE and String(payload.get("action_state", "")) == "active", "Held payload profile/state mismatch: %s" % str(payload))
			_assert(not bool(payload.get("turn_keys_steer_joint", true)), "Held payload should read module_part turn-key steering fallback: %s" % str(payload))
			_assert(float(payload.get("hold_time", -1.0)) == 0.0, "Held payload hold time should initialize to zero: %s" % str(payload))
			payload["binding"]["attack_key"] = 99
			var clean_payload: Dictionary = service.held_activation_state_payload({"binding": {"attack_key": 3}})
			_assert(int(Dictionary(clean_payload.get("binding", {})).get("attack_key", 0)) == 3, "Held payload should duplicate binding data.")
			if not service.has_method("turn_input_from_strengths"):
				_fail("HeldMeleeActivationService missing turn_input_from_strengths.")
			else:
				_assert(absf(float(service.turn_input_from_strengths(0.54, 0.14)) - 0.4) < 0.001, "Turn input should subtract left from right strengths.")
				_assert(float(service.turn_input_from_strengths(0.06, 0.0)) == 0.0, "Turn input should respect the default deadzone.")
				_assert(float(service.turn_input_from_strengths(2.0, 0.0)) == 1.0, "Turn input should clamp positive values.")
				_assert(float(service.turn_input_from_strengths(0.0, 2.0)) == -1.0, "Turn input should clamp negative values.")
			if not service.has_method("tick_state_payload"):
				_fail("HeldMeleeActivationService missing tick_state_payload.")
			else:
				var ticked: Dictionary = service.tick_state_payload({"hold_time": 0.25, "turn_input": 0.0, "binding": {"attack_key": 1}}, 0.4, 0.125)
				_assert(absf(float(ticked.get("hold_time", 0.0)) - 0.375) < 0.001, "Tick payload should add delta to hold_time: %s" % str(ticked))
				_assert(absf(float(ticked.get("turn_input", 0.0)) - 0.4) < 0.001, "Tick payload should preserve normalized turn input: %s" % str(ticked))
				_assert(int(Dictionary(ticked.get("binding", {})).get("attack_key", 0)) == 1, "Tick payload should preserve other state fields: %s" % str(ticked))
			if not service.has_method("activation_state_active"):
				_fail("HeldMeleeActivationService missing activation_state_active.")
			else:
				_assert(not service.activation_state_active({}), "Empty held activation state should not be active.")
				_assert(service.activation_state_active({"action_name": "p1_attack_1"}), "Non-empty held activation state should be active.")
			if not service.has_method("held_turn_keys_reserved"):
				_fail("HeldMeleeActivationService missing held_turn_keys_reserved.")
			else:
				_assert(not service.held_turn_keys_reserved({}), "Empty held state should not reserve turn keys.")
				_assert(service.held_turn_keys_reserved({"turn_keys_steer_joint": true}), "True turn-key steering state should reserve turn keys.")
				_assert(not service.held_turn_keys_reserved({"turn_keys_steer_joint": false}), "False turn-key steering state should not reserve turn keys.")
				_assert(service.held_turn_keys_reserved({"binding": {"attack_key": 1}}), "Missing turn-key steering flag should default to reserved for active held state.")
			if not service.has_method("should_release_hold"):
				_fail("HeldMeleeActivationService missing should_release_hold.")
			else:
				_assert(service.should_release_hold("", false, true), "Empty action name should release held activation.")
				_assert(service.should_release_hold("p1_attack_1", true, true), "Just released action should release held activation.")
				_assert(service.should_release_hold("p1_attack_1", false, false), "Unpressed action should release held activation.")
				_assert(not service.should_release_hold("p1_attack_1", false, true), "Pressed non-released action should keep held activation.")
			if not service.has_method("held_activation_event_payload"):
				_fail("HeldMeleeActivationService missing held_activation_event_payload.")
			else:
				var patched_event: Dictionary = service.held_activation_event_payload({"damage_type": "slash", "damage": 7.0})
				_assert(not bool(patched_event.get("projectile", true)), "Held melee event should not be projectile: %s" % str(patched_event))
				_assert(not bool(patched_event.get("projectile_only", true)), "Held melee event should not be projectile-only: %s" % str(patched_event))
				_assert(bool(patched_event.get("runtime_melee_contact", false)), "Held melee event should mark runtime melee contact: %s" % str(patched_event))
				_assert(bool(patched_event.get("boot_driver_held_activation", false)), "Held melee event should mark Boot Driver held activation: %s" % str(patched_event))
				_assert(String(patched_event.get("damage_type", "")) == "slash" and absf(float(patched_event.get("damage", 0.0)) - 7.0) < 0.001, "Held melee event should preserve existing fields: %s" % str(patched_event))
				var default_damage_event: Dictionary = service.held_activation_event_payload({})
				_assert(String(default_damage_event.get("damage_type", "")) == "blunt", "Held melee event should default damage_type to blunt: %s" % str(default_damage_event))
			if not service.has_method("activation_direction"):
				_fail("HeldMeleeActivationService missing activation_direction.")
			else:
				var segment_direction: Vector2 = service.activation_direction({"target_nodes": [1, 2]}, {"a": Vector2(1, 1), "b": Vector2(3, 1)}, Vector2.UP, Vector2.LEFT)
				_assert((segment_direction - Vector2.RIGHT).length() < 0.001, "Activation direction should prefer rotating segment direction when the binding has at least two target nodes: %s" % str(segment_direction))
				var fallback_direction: Vector2 = service.activation_direction({"target_nodes": [1]}, {"a": Vector2(1, 1), "b": Vector2(3, 1)}, Vector2.DOWN, Vector2.LEFT)
				_assert((fallback_direction - Vector2.DOWN).length() < 0.001, "Activation direction should ignore rotating segment when binding has fewer than two target nodes: %s" % str(fallback_direction))
				var input_direction: Vector2 = service.activation_direction({"target_nodes": [1, 2]}, {"a": Vector2(1, 1), "b": Vector2(1, 1)}, Vector2.ZERO, Vector2.LEFT)
				_assert((input_direction - Vector2.LEFT).length() < 0.001, "Activation direction should fall back to normalized input when segment and forward vector are missing: %s" % str(input_direction))
				var zero_direction: Vector2 = service.activation_direction({"target_nodes": [1, 2]}, {}, Vector2.ZERO, Vector2.ZERO)
				_assert(zero_direction.length() < 0.001, "Activation direction should stay zero when segment, forward vector, and input are all missing: %s" % str(zero_direction))
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"scripts/services/held_melee_activation_service.gd",
		"HeldMeleeActivationService.new",
		"_held_melee_activation_service().runtime_binding_is_held_melee_activation",
		"_held_melee_activation_service().boot_driver_initial_state",
		"_held_melee_activation_service().held_activation_state_payload",
		"_held_melee_activation_service().turn_input_from_strengths",
		"_held_melee_activation_service().tick_state_payload",
		"_held_melee_activation_service().activation_state_active",
		"_held_melee_activation_service().held_turn_keys_reserved",
		"_held_melee_activation_service().should_release_hold",
		"_held_melee_activation_service().held_activation_event_payload",
		"_held_melee_activation_service().activation_direction",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd missing HeldMeleeActivationService boundary token: %s" % token)
	if not failures.is_empty():
		print("HELD_MELEE_ACTIVATION_SERVICE_CONTRACT_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("HELD_MELEE_ACTIVATION_SERVICE_CONTRACT_PROBE ok")
	quit(0)
