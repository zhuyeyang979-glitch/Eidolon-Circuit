extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ai_battle_seat = 3
	main._legalize_ai_player_roster(1, true)
	main._legalize_ai_player_roster(2, true)
	var p1_summary: Dictionary = main._team_battle_entry_summary(1)
	var p2_summary: Dictionary = main._team_battle_entry_summary(2)
	main._start_battle(MainScene.MODE_AI)
	var state_after_start := String(main.game_state)
	if state_after_start == MainScene.STATE_SCOUT:
		main._try_begin_battle_from_scout()
	var state_after_scout := String(main.game_state)
	print("AI_ENTRY_PROBE p1_valid=%s p2_valid=%s start_state=%s final_state=%s units=%d p1=%s p2=%s" % [
		str(bool(p1_summary.get("valid", false))),
		str(bool(p2_summary.get("valid", false))),
		state_after_start,
		state_after_scout,
		main.all_units.size(),
		String(p1_summary.get("note", "")),
		String(p2_summary.get("note", "")),
	])
	if not bool(p1_summary.get("valid", false)):
		push_error("P1 AI roster is not battle legal")
	if not bool(p2_summary.get("valid", false)):
		push_error("P2 AI roster is not battle legal")
	if state_after_scout != MainScene.STATE_BATTLE:
		push_error("Computer Battle did not enter battle state")
	if main.all_units.size() < 2:
		push_error("Computer Battle did not spawn both starting units")
	quit()
