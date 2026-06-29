extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleInputServiceScript := preload("res://scripts/services/battle_input_service.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _assert_contains(label: String, text: String, phrase: String) -> void:
	if text.find(phrase) < 0:
		_fail("%s missing phrase: %s" % [label, phrase])


func _assert_not_contains(label: String, text: String, phrase: String) -> void:
	if text.find(phrase) >= 0:
		_fail("%s should not contain phrase: %s" % [label, phrase])


func _action_has_key(action_name: String, keycode: int) -> bool:
	if not InputMap.has_action(action_name):
		return false
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var code := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			if code == keycode:
				return true
	return false


func _init() -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	_assert_contains("README", readme, "## Tactical Input Model")
	_assert_contains("README", readme, "High-frequency hero control")
	_assert_contains("README", readme, "Low-frequency tactical commands")
	_assert_contains("README", readme, "not direct micromanagement")
	_assert_contains("README", readme, "Manual cooling: hold `G`")
	_assert_contains("README", readme, "Summon portal: tap `Tab` to cycle")
	_assert_contains("README", readme, "hold a direction and tap `Tab` to direct-select")
	_assert_contains("README", readme, "deploy through the selected portal")
	_assert_not_contains("README", readme, "Cycle summon portal: `Q`")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_assert_contains("main.gd", main_source, "_battle_action_pressed(\"%s_cool\" % prefix)")
	_assert_contains("main.gd", main_source, "_battle_action_strength(\"%s_right\" % prefix)")
	_assert_not_contains("main.gd", main_source, "if Input.is_action_pressed(\"%s_cool\" % prefix)")
	_assert_contains("main.gd", main_source, "hero.manual_cool(delta)")

	var service = BattleInputServiceScript.new()
	if not service.has_method("tactical_input_contract"):
		_fail("BattleInputService missing tactical_input_contract().")
	else:
		var contract: Dictionary = service.tactical_input_contract()
		for key in ["high_frequency_hero", "mid_frequency_tactical", "low_frequency_preset", "forbidden_runtime_micro", "cognitive_load_guardrails"]:
			if not contract.has(key):
				_fail("Tactical input contract missing key: %s" % key)
		var high := PackedStringArray(contract.get("high_frequency_hero", []))
		var mid := PackedStringArray(contract.get("mid_frequency_tactical", []))
		var low := PackedStringArray(contract.get("low_frequency_preset", []))
		var forbidden := PackedStringArray(contract.get("forbidden_runtime_micro", []))
		for required in ["move", "turn", "boost", "attack", "manual_cooling"]:
			if not high.has(required):
				_fail("High-frequency hero contract missing %s." % required)
		for required in ["cycle_portal", "pair_summon", "deploy_hero", "deploy_puppet", "deploy_barrier"]:
			if not mid.has(required):
				_fail("Mid-frequency tactical contract missing %s." % required)
		for required in ["puppet_source_code", "barrier_ether_logic"]:
			if not low.has(required):
				_fail("Low-frequency preset contract missing %s." % required)
		for blocked in ["puppet_direct_move", "puppet_direct_attack", "barrier_direct_move", "barrier_direct_attack"]:
			if not forbidden.has(blocked):
				_fail("Forbidden runtime micro contract missing %s." % blocked)
		var guardrails: Dictionary = contract.get("cognitive_load_guardrails", {})
		if String(guardrails.get("primary_runtime_focus", "")) != "hero":
			_fail("Cognitive load guardrails should keep hero as the primary runtime focus.")
		if int(guardrails.get("max_simultaneous_direct_control_roles", 0)) != 1:
			_fail("Cognitive load guardrails should limit high-frequency direct control to one role.")
		if PackedStringArray(guardrails.get("direct_control_roles", [])).has("puppet") or PackedStringArray(guardrails.get("direct_control_roles", [])).has("barrier"):
			_fail("Puppets and barriers should not become high-frequency direct-control roles.")
		var action_names := PackedStringArray(service.battle_action_names(["p1"], 6))
		for blocked_action in ["p1_puppet_move", "p1_puppet_attack", "p1_barrier_move", "p1_barrier_attack"]:
			if action_names.has(blocked_action):
				_fail("Battle input action list exposes forbidden micro action: %s" % blocked_action)
		if not action_names.has("p1_cool"):
			_fail("Battle input action list should include hero manual cooling.")
		if not action_names.has("p1_portal"):
			_fail("Battle input action list should include tactical portal.")

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ui_language = MainScene.UI_LANGUAGE_ZH
	_assert_contains("Chinese battle help", main._battle_help_text(), "英雄高频")
	_assert_contains("Chinese battle help", main._battle_help_text(), "战术低频")
	_assert_contains("Chinese battle help", main._battle_help_text(), "双攻击键")
	main.ui_language = MainScene.UI_LANGUAGE_EN
	_assert_contains("English battle help", main._battle_help_text(), "High-frequency hero")
	_assert_contains("English battle help", main._battle_help_text(), "Low-frequency tactics")
	_assert_contains("English battle help", main._battle_help_text(), "paired attack buttons")

	main._show_settings(true, "input")
	if not main.battle_input_buttons.has("p1_cool"):
		_fail("Settings input list should expose P1 hero manual cooling.")
	if not main.battle_input_buttons.has("p2_cool"):
		_fail("Settings input list should expose P2 hero manual cooling.")
	if not main.battle_input_buttons.has("p1_portal"):
		_fail("Settings input list should expose P1 tactical portal control.")
	if not main.battle_input_buttons.has("p2_portal"):
		_fail("Settings input list should expose P2 tactical portal control.")
	if not InputMap.has_action("p1_cool"):
		_fail("InputMap missing p1_cool action.")
	if not _action_has_key("p1_cool", KEY_G):
		_fail("P1 hero manual cooling should default to G.")
	if not InputMap.has_action("p1_portal"):
		_fail("InputMap missing p1_portal action.")
	if not _action_has_key("p1_portal", KEY_TAB):
		_fail("P1 tactical portal should default to Tab.")

	print("TACTICAL_INPUT_CONTRACT_PROBE failed=%s" % str(failed))
	quit(1 if failed else 0)
