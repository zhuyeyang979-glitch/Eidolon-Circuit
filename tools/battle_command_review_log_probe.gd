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


func _assert_not_contains(label: String, text: String, phrase: String) -> void:
	if text.find(phrase) >= 0:
		_fail("%s should not contain phrase: %s" % [label, phrase])


func _new_main() -> Object:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._begin_battle(MainScene.MODE_PVP, true, "battle_command_review_log_probe")
	main.battle_message = ""
	main.match_time_remaining = MainScene.MATCH_TARGET_SECONDS - 12.4
	return main


func _init() -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	_assert_contains("README", readme, "## Command Review Log")
	_assert_contains("README", readme, "not shown as live HUD text")
	_assert_contains("README", readme, "post-battle review")

	var plan := FileAccess.get_file_as_string("res://docs/plans/2026-06-15-command-review-log.md")
	_assert_contains("plan", plan, "move armor and active command cache feedback out of live combat HUD text")
	_assert_contains("plan", plan, "battle_command_log")
	_assert_contains("plan", plan, "PostBattleReviewCommandLog")

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for required in [
		"BATTLE_COMMAND_LOG_LIMIT",
		"battle_command_log",
		"_note_battle_command_cache",
		"_record_battle_command_log",
		"_battle_command_log_summary_text",
	]:
		_assert_contains("main.gd", main_source, required)
	_assert_not_contains("main.gd", main_source, "装甲指令已缓存")
	_assert_not_contains("main.gd", main_source, "主动指令已缓存")

	var menu_view_source := FileAccess.get_file_as_string("res://scripts/views/menu_view.gd")
	_assert_contains("menu_view.gd", menu_view_source, "PostBattleReviewCommandLog")

	var controller = MenuControllerScript.new()
	var controller_model: Dictionary = controller.post_battle_review_model("zh", 1, {1: 2, 2: 1}, 42.0, MainScene.MODE_PVP, "指令日志\nP1 1.0s 缓存 主动 24")
	if String(controller_model.get("command_log", "")).find("缓存 主动") < 0:
		_fail("Post-battle review model should carry command_log text.")

	var main = _new_main()
	main.command_buffers[1] = ["2", "6"]
	main._note_battle_command_cache(1)
	main.command_buffers[1] = ["2", "4"]
	main._note_battle_command_cache(1)
	main._record_battle_command_log(1, "match", "236214", "special", "command_skill", -1, true)
	if main.battle_message != "":
		_fail("Command cache logging should not write live battle HUD message text.")
	if main.battle_command_log.size() < 3:
		_fail("Command review log should contain cache and match records.")
	var summary: String = main._battle_command_log_summary_text(5)
	_assert_contains("summary", summary, "缓存")
	_assert_contains("summary", summary, "装甲")
	_assert_contains("summary", summary, "主动")
	_assert_contains("summary", summary, "特殊")

	main._show_post_battle_review(1, "probe")
	var label = main.post_battle_review_panel.find_child("PostBattleReviewCommandLog", true, false)
	if not (label is Label):
		_fail("Post-battle review should contain PostBattleReviewCommandLog label.")
	elif String(label.text).find("指令日志") < 0 or String(label.text).find("缓存") < 0:
		_fail("Post-battle review command log label should show recorded command text.")

	print("BATTLE_COMMAND_REVIEW_LOG_PROBE failed=%s" % str(failed))
	quit(1 if failed else 0)
