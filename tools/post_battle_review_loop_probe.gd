extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MenuControllerScript := preload("res://scripts/controllers/menu_controller.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _assert_contains(label: String, text: String, phrase: String) -> void:
	if text.find(phrase) < 0:
		_fail("%s missing phrase: %s" % [label, phrase])


func _new_battle_main() -> Object:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._begin_battle(MainScene.MODE_PVP, true, "post_battle_review_probe")
	return main


func _finish_battle(main: Object, winner_id: int = 1) -> void:
	main.victory_points = {1: 3, 2: 2}
	main.match_time_remaining = 123.0
	main._end_battle(winner_id)


func _init() -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	_assert_contains("README", readme, "## Post-Battle Review Loop")
	_assert_contains("README", readme, "does not force the player into editing")
	_assert_contains("README", readme, "player decides when to revise the build")

	var controller = MenuControllerScript.new()
	var model: Dictionary = controller.post_battle_review_model("zh", 1, {1: 3, 2: 2}, 123.0, MainScene.MODE_PVP)
	for key in ["title", "summary", "hint", "items"]:
		if not model.has(key):
			_fail("Post-battle review model missing key: %s" % key)
	var item_keys := []
	for raw_item in Array(model.get("items", [])):
		if raw_item is Dictionary:
			item_keys.append(String(Dictionary(raw_item).get("key", "")))
	for required in ["review", "adjust_sortie", "edit_units", "rematch", "main_menu"]:
		if not item_keys.has(required):
			_fail("Post-battle review items missing: %s" % required)

	var main = _new_battle_main()
	_finish_battle(main, 1)
	if main.game_state != MainScene.STATE_BATTLE:
		_fail("Battle end should not auto-navigate away from battle; got %s." % String(main.game_state))
	if not bool(main.game_over):
		_fail("Battle end should set game_over.")
	if main.post_battle_review_panel == null or not bool(main.post_battle_review_panel.visible):
		_fail("Post-battle review panel should be visible after battle end.")
	if not main.post_battle_review_buttons.has("adjust_sortie") or not main.post_battle_review_buttons.has("edit_units") or not main.post_battle_review_buttons.has("rematch"):
		_fail("Post-battle review panel missing expected action buttons.")

	main._post_battle_review_action("review")
	if main.game_state != MainScene.STATE_BATTLE:
		_fail("Review action should keep the player on the battle page.")
	if main.post_battle_review_panel != null and bool(main.post_battle_review_panel.visible):
		_fail("Review action should hide the panel and leave the frozen field inspectable.")

	var scout_main = _new_battle_main()
	_finish_battle(scout_main, 1)
	scout_main._post_battle_review_action("adjust_sortie")
	if scout_main.game_state != MainScene.STATE_SCOUT or scout_main.pending_battle_mode != MainScene.MODE_PVP:
		_fail("Adjust sortie should route to Scout for the same battle mode; got page=%s mode=%s." % [String(scout_main.game_state), String(scout_main.pending_battle_mode)])

	var editor_main = _new_battle_main()
	_finish_battle(editor_main, 1)
	editor_main._post_battle_review_action("edit_units")
	if editor_main.game_state != MainScene.STATE_EDITOR:
		_fail("Edit units should route to Team Edit; got %s." % String(editor_main.game_state))

	var rematch_main = _new_battle_main()
	_finish_battle(rematch_main, 1)
	rematch_main._post_battle_review_action("rematch")
	if rematch_main.game_state != MainScene.STATE_BATTLE or bool(rematch_main.game_over):
		_fail("Rematch should start a fresh battle and clear game_over.")

	print("POST_BATTLE_REVIEW_LOOP_PROBE failed=%s" % str(failed))
	quit(1 if failed else 0)
