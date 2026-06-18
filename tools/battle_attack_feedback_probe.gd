extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const BattleAttackFeedbackView := preload("res://scripts/views/battle_attack_feedback_view.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _assert_contains(label: String, text: String, phrase: String) -> void:
	if text.find(phrase) < 0:
		_fail("%s missing phrase: %s" % [label, phrase])


func _init() -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	_assert_contains("README", readme, "## Attack Group Feedback")
	_assert_contains("README", readme, "READY, AIM, LOCK, FIRE, CMD, COOL, HEAT, BLOCK, EMPTY, or SEVER")
	_assert_contains("README", readme, "advisory feedback only")

	var plan := FileAccess.get_file_as_string("res://docs/plans/2026-06-15-attack-group-feedback.md")
	_assert_contains("plan", plan, "Make every attack-group input visibly legible")
	_assert_contains("plan", plan, "BattleAttackFeedbackView")
	_assert_contains("plan", plan, "_record_attack_feedback()")

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for required in [
		"scripts/views/battle_attack_feedback_view.gd",
		"BattleAttackFeedbackView.new",
		"battle_attack_feedback_events",
		"_record_attack_feedback",
		"_battle_attack_feedback_model",
		"_battle_attack_feedback_slot",
		"_attack_feedback_status_label",
		"_update_attack_feedback_hud",
	]:
		_assert_contains("main.gd", main_source, required)
	for status_token in ["\"aim\"", "\"lock\"", "\"fire\"", "\"block\"", "\"empty\"", "\"window\""]:
		_assert_contains("main.gd", main_source, status_token)

	var fighter_source := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	for required in [
		"pulse_attack_feedback",
		"attack_feedback_timers",
		"_tick_attack_feedback_pulses",
		"_attack_feedback_overlay_color",
		"draw_runtime_segment_status_overlay",
	]:
		_assert_contains("fighter.gd", fighter_source, required)

	var view := BattleAttackFeedbackView.new()
	root.add_child(view)
	view.size = Vector2(420.0, 72.0)
	view.set_model({
		"visible": true,
		"player_id": 1,
		"title": "P1 ATTACK GROUPS",
		"slots": _sample_slots(),
	})
	if view.slot_count() != 6:
		_fail("BattleAttackFeedbackView should expose six slots.")
	var snapshot: Dictionary = view.debug_snapshot()
	var slots: Array = Array(snapshot.get("slots", []))
	if slots.size() != 6 or String(Dictionary(slots[0]).get("status", "")) != "fire":
		_fail("BattleAttackFeedbackView debug snapshot should preserve slot status.")
	view.free()

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "FeedbackProbe",
		"stats": {
			"health": 100,
			"mass": 12.0,
			"move_speed": 4.0,
			"boost_speed": 7.0,
			"boost_momentum": 120.0,
			"heat_capacity": 80.0,
			"ammo_capacity": {"bullet": 6, "chemical": 0, "laser": 0, "explosive": 0, "web": 0},
		},
	})
	unit.deploy(0.0, 0.0)
	main._initialize_unit_runtime_resources(unit)
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	main.ai_battle_seat = 1
	main.active_units = {
		1: {"hero": unit, "puppet": [], "barrier": null},
		2: {"hero": null, "puppet": [], "barrier": null},
	}
	main._record_attack_feedback(1, 0, "fire", "probe", 0.0, 0.75)
	var model: Dictionary = main._battle_attack_feedback_model(1)
	var model_slots: Array = Array(model.get("slots", []))
	if model_slots.size() != 6:
		_fail("Attack feedback model should contain six attack-group slots.")
	else:
		var first: Dictionary = Dictionary(model_slots[0])
		if String(first.get("key_label", "")) != "U":
			_fail("First attack feedback slot should use U key label.")
		if String(first.get("status", "")) != "fire":
			_fail("Fresh feedback event should override first slot status to FIRE.")
		if float(first.get("flash_ratio", 0.0)) <= 0.0:
			_fail("Fresh feedback event should expose a positive flash ratio.")
	if not unit.attack_feedback_timers.has("0"):
		_fail("Fighter should receive a corresponding attack feedback pulse.")
	main._update_attack_feedback_hud()
	if main.battle_attack_feedback_view == null or not main.battle_attack_feedback_view.visible:
		_fail("Battle attack feedback view should be visible for a controlled hero.")

	print("BATTLE_ATTACK_FEEDBACK_PROBE failed=%s" % str(failed))
	quit(1 if failed else 0)


func _sample_slots() -> Array:
	var slots: Array = []
	var statuses := ["fire", "aim", "lock", "block", "empty", "ready"]
	var keys := ["U", "I", "O", "J", "K", "L"]
	for i in range(6):
		slots.append({
			"index": i,
			"group": i + 1,
			"key_label": keys[i],
			"name": "GROUP%d" % [i + 1],
			"status": statuses[i],
			"status_label": statuses[i].to_upper(),
			"flash_ratio": 1.0 if i == 0 else 0.0,
			"heat_ratio": 0.25,
			"cooldown_ratio": 0.15,
			"ammo_kind": "bullet",
			"ammo_current": 4,
			"ammo_capacity": 6,
		})
	return slots
