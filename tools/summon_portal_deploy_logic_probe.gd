extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleActorCommandServiceScript := preload("res://scripts/services/battle_actor_command_service.gd")

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


func _init() -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	_assert_contains("README", readme, "hold a direction and tap `Tab` to direct-select")
	_assert_contains("README", readme, "deploy through the selected portal")
	_assert_contains("README", readme, "no longer steals the live movement direction")

	var plan := FileAccess.get_file_as_string("res://docs/plans/2026-06-15-summon-portal-deploy-logic.md")
	_assert_contains("plan", plan, "Separate entrance selection from deployment confirmation")
	_assert_contains("plan", plan, "summon_portal_selection_intent")
	_assert_contains("plan", plan, "Do not let the movement vector at pair-press time silently change the portal")

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for required in [
		"_battle_actor_command_service().summon_portal_selection_intent",
		"_select_summon_portal_for_input",
		"_summon_portal_feedback_text",
		"func _summon_sortie_slot(player_id: int, slot_index: int)",
		"_summon_commit_feedback_text",
	]:
		_assert_contains("main.gd", main_source, required)
	_assert_not_contains("main.gd", main_source, "func _summon_sortie_slot(player_id: int, slot_index: int, input_vector")
	_assert_not_contains("main.gd", main_source, "_portal_index_from_vector(input_vector, int(portal_index[player_id]))")

	var service = BattleActorCommandServiceScript.new()
	var cycle: Dictionary = service.summon_portal_selection_intent(Vector2.ZERO, 3, 8)
	if String(cycle.get("selection", "")) != "cycle" or int(cycle.get("portal_index", -1)) != 4:
		_fail("Neutral portal input should cycle from 3 to 4: %s" % str(cycle))
	var direct: Dictionary = service.summon_portal_selection_intent(Vector2(-0.7, -0.7), 4, 8)
	if String(direct.get("selection", "")) != "direct" or int(direct.get("portal_index", -1)) != 0:
		_fail("Strong direction should direct-select portal 0: %s" % str(direct))

	var main = MainScene.new()
	root.add_child(main)
	main.ui_language = MainScene.UI_LANGUAGE_ZH
	main._ready()
	main._legalize_ai_player_roster(1, true)
	main.portal_index[1] = 3
	var cycle_intent: Dictionary = main._select_summon_portal_for_input(1, Vector2.ZERO)
	if int(main.portal_index[1]) != 4 or String(cycle_intent.get("selection", "")) != "cycle":
		_fail("main portal selection should cycle without direction.")
	var direct_intent: Dictionary = main._select_summon_portal_for_input(1, Vector2(-0.7, -0.7))
	if int(main.portal_index[1]) != 0 or String(direct_intent.get("selection", "")) != "direct":
		_fail("main portal selection should direct-select with a strong direction.")

	main._begin_battle(MainScene.MODE_PVP, true, "summon_portal_deploy_logic_probe")
	var portal_feedback: String = main._summon_portal_feedback_text(1, "direct")
	_assert_contains("portal feedback", portal_feedback, "直选")
	_assert_contains("portal feedback", portal_feedback, "组合召唤")
	_assert_contains("portal feedback", portal_feedback, "$")
	main.runtime_resource[1] = 9999.0
	main.sortie_loadouts[1] = [{"role": "puppet", "index": 0}]
	main.summon_pair_bindings[1] = [[1, 2]]
	main.portal_index[1] = 0
	var accepted := main._summon_sortie_slot(1, 0)
	if not accepted:
		_fail("Puppet sortie slot should be accepted for pending deploy.")
	if int(main.portal_index[1]) != 0:
		_fail("Summon slot commit should not change the selected portal.")
	if not bool(main._role_pending(1, "puppet")):
		_fail("Accepted puppet summon should create a pending deploy.")
	var snapshot: Dictionary = main._pending_deploy_snapshot(1, "puppet")
	if not snapshot.has("ring") or not snapshot.has("lane"):
		_fail("Pending puppet deploy should store selected portal spawn snapshot.")
	_assert_contains("battle message", main.battle_message, "槽1")
	_assert_contains("battle message", main.battle_message, "入场")
	_assert_contains("battle message", main.battle_message, "消耗")

	print("SUMMON_PORTAL_DEPLOY_LOGIC_PROBE failed=%s" % str(failed))
	quit(1 if failed else 0)
