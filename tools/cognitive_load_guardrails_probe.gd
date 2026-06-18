extends SceneTree

const BattleInputServiceScript := preload("res://scripts/services/battle_input_service.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _assert_contains(label: String, text: String, phrase: String) -> void:
	if text.find(phrase) < 0:
		_fail("%s missing phrase: %s" % [label, phrase])


func _assert_array_has(label: String, values: Array, expected: String) -> void:
	if not PackedStringArray(values).has(expected):
		_fail("%s missing %s." % [label, expected])


func _init() -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	_assert_contains("README", readme, "## Cognitive Load Guardrails")
	_assert_contains("README", readme, "hero as the only high-frequency direct-control focus")
	_assert_contains("README", readme, "Puppets and barriers are tactical commitments")
	_assert_contains("README", readme, "not in overloading the player's attention")
	var plan := FileAccess.get_file_as_string("res://docs/plans/2026-06-15-cognitive-load-guardrails.md")
	_assert_contains("plan", plan, "Hero control owns the fast loop")
	_assert_contains("plan", plan, "must not add continuous puppet movement axes")
	_assert_contains("plan", plan, "BattleInputService.cognitive_load_contract()")

	var service = BattleInputServiceScript.new()
	if not service.has_method("cognitive_load_contract"):
		_fail("BattleInputService missing cognitive_load_contract().")
	else:
		var contract: Dictionary = service.cognitive_load_contract()
		if String(contract.get("primary_runtime_focus", "")) != "hero":
			_fail("Primary runtime focus should be hero.")
		if int(contract.get("max_simultaneous_direct_control_roles", 0)) != 1:
			_fail("Only one role should be under high-frequency direct control.")
		var direct_roles := Array(contract.get("direct_control_roles", []))
		if direct_roles.size() != 1 or String(direct_roles[0]) != "hero":
			_fail("Direct-control roles should contain only hero: %s" % str(direct_roles))
		var tactical_roles := Array(contract.get("tactical_commit_roles", []))
		_assert_array_has("tactical roles", tactical_roles, "puppet")
		_assert_array_has("tactical roles", tactical_roles, "barrier")
		var styles := Array(contract.get("tactical_command_style", []))
		for expected in ["cycle_portal", "pair_summon_chord", "deploy_prebuilt_slot"]:
			_assert_array_has("tactical command style", styles, expected)
		var conflicts := Array(contract.get("conflict_resolution", []))
		for expected in ["hero_aim_reserves_turn_keys", "attack_window_blocks_pair_summon", "movement_remains_on_wasd_during_aim", "puppet_barrier_runtime_logic_is_preset"]:
			_assert_array_has("conflict resolution", conflicts, expected)
		var forbidden := Array(contract.get("forbidden_runtime_micro", []))
		for expected in ["puppet_direct_move", "puppet_direct_attack", "puppet_direct_aim", "barrier_direct_move", "barrier_direct_attack", "barrier_direct_aim"]:
			_assert_array_has("forbidden runtime micro", forbidden, expected)
		var gates := Array(contract.get("new_feature_gate", []))
		for expected in ["no_new_continuous_puppet_axis", "no_new_continuous_barrier_axis", "prefer_authoring_or_deploy_commit"]:
			_assert_array_has("new feature gate", gates, expected)

		var tactical: Dictionary = service.tactical_input_contract()
		if not tactical.has("cognitive_load_guardrails"):
			_fail("Tactical input contract should embed cognitive load guardrails.")
		var embedded: Dictionary = tactical.get("cognitive_load_guardrails", {})
		if String(embedded.get("primary_runtime_focus", "")) != "hero":
			_fail("Embedded cognitive load contract should keep hero as primary focus.")

	var action_names := PackedStringArray(service.battle_action_names(["p1", "p2"], 6))
	for action_name in action_names:
		if String(action_name).find("puppet") >= 0 or String(action_name).find("barrier") >= 0:
			_fail("Runtime action list should not expose puppet/barrier micro action: %s" % String(action_name))
	for required in ["p1_left", "p1_right", "p1_up", "p1_down", "p1_face_left", "p1_face_right", "p1_portal", "p1_cool"]:
		if not action_names.has(required):
			_fail("Runtime action list lost expected hero/tactical action: %s" % required)

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_assert_contains("main.gd", main_source, "turn_keys_reserved_for_weapon_aim")
	_assert_contains("main.gd", main_source, "_held_aim_uses_turn_keys(player_id, prefix)")
	_assert_contains("main.gd", main_source, "not _attack_windows_any_open(player_id) and not _runtime_gun_activation_active(player_id) and not _runtime_held_melee_activation_active(player_id) and _try_attack_pair_summon")

	print("COGNITIVE_LOAD_GUARDRAILS_PROBE failed=%s" % str(failed))
	quit(1 if failed else 0)
