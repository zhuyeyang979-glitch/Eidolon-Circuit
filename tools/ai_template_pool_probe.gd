extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var failures := 0
	for player_id in [1, 2]:
		for template_key in MainScene.AI_TEAM_TEMPLATE_ORDER:
			main.ai_team_template_choice[player_id] = template_key
			main.ai_team_manual_lock[player_id] = false
			main._legalize_ai_player_roster(player_id, true)
			var summary: Dictionary = main._team_battle_entry_summary(player_id)
			var sortie := main._team_sortie_order(player_id)
			var starter := main._starter_sortie_entry(player_id)
			print("AI_TEMPLATE player=%d key=%s valid=%s sortie=%d starter=%s note=%s" % [
				player_id,
				String(template_key),
				str(bool(summary.get("valid", false))),
				sortie.size(),
				main._sortie_entry_label(player_id, starter),
				String(summary.get("note", "")),
			])
			if not bool(summary.get("valid", false)):
				failures += 1
				push_error("AI template %s for P%d is not battle legal" % [String(template_key), player_id])
	if failures > 0:
		quit(1)
		return
	quit()
