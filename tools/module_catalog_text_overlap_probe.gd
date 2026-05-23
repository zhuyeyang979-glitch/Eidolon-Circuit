extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _check_language(main, language: String) -> void:
	main.ui_language = language
	var zh := language == MainScene.UI_LANGUAGE_ZH
	var max_line_len := 24 if zh else 32
	var catalog: Array = main._catalog_for("hero", "module")
	for raw_part in catalog:
		if raw_part is Dictionary:
			var part: Dictionary = raw_part
			var lines: Array = main._catalog_card_data_lines("module", part)
			for line in lines:
				var text := String(line)
				if text.length() > max_line_len:
					_fail("Module card line too long in %s: %s" % [language, text])
					return
				if text.find("Action Module >") >= 0 or text.find("行动模块 >") >= 0:
					_fail("Module card line used long category path: %s" % text)
					return
			var detail_lines: Array = main._hover_card_player_detail_lines("module", part)
			var found_path := false
			for detail_line in detail_lines:
				var detail := String(detail_line)
				if (zh and detail.find("行动模块 >") >= 0) or ((not zh) and detail.find("Action Module >") >= 0):
					found_path = true
					break
			if not found_path:
				_fail("Module hover did not include category path for %s in %s." % [String(part.get("name", "")), language])
				return


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	_check_language(main, MainScene.UI_LANGUAGE_ZH)
	_check_language(main, MainScene.UI_LANGUAGE_EN)
	print("MODULE_CATALOG_TEXT_OVERLAP_PROBE ok")
	quit(0)
