extends SceneTree

const MainScene := preload("res://scripts/main.gd")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main.ui_language = MainScene.UI_LANGUAGE_ZH
	main._ready()
	main.ai_battle_seat = 1
	main._start_battle(MainScene.MODE_AI)
	main._update_battle_ui()
	var texts := PackedStringArray()
	texts.append(main.battle_mode_label.text)
	texts.append(main.battle_message_label.text)
	for player_id in [1, 2]:
		texts.append(main.resource_labels[player_id].text)
		texts.append(main.victory_labels[player_id].text)
		texts.append(main.portal_labels[player_id].text)
		for label in main.unit_status_labels[player_id]:
			texts.append(label.text)
		for role_key in MainScene.ROLE_ORDER:
			texts.append(main.role_bar_labels[player_id][role_key].text)
	var forbidden := ["PUPPET", "DEPLOY", "OFFLINE", "RESOURCE", "VICTORY POINTS", "PORTAL", "COMPUTER BATTLE"]
	for text in texts:
		for token in forbidden:
			if text.find(token) >= 0:
				_fail("Chinese battle UI still contains '%s' in: %s" % [token, text])
	print("BATTLE_TRANSLATION_PROBE checked=%d language=zh" % texts.size())
	quit()
