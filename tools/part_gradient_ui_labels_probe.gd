extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_gradient_text(text: String, context: String) -> void:
	if text.find("/") < 0:
		_fail("%s should expose tier/role/tradeoff gradient text: %s" % [context, text])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	for slot_key in ["engine", "booster", "cooling", "limb_muscle", "module"]:
		var part: Dictionary = main._selected_component("hero", slot_key, 0)
		var lines: Array = main._catalog_card_data_lines(slot_key, part)
		if lines.size() < 2:
			_fail("%s catalog card should have two data lines." % slot_key)
		_assert_gradient_text(String(lines[1]), "%s card" % slot_key)
		var detail_lines: Array = main._hover_card_player_detail_lines(slot_key, part)
		var found := false
		for line in detail_lines:
			var text := String(line)
			if text.find("#梯度") >= 0 or text.find("#Gradient") >= 0:
				found = true
				_assert_gradient_text(text, "%s hover" % slot_key)
				break
		if not found:
			_fail("%s hover should include gradient detail line." % slot_key)
	print("PART_GRADIENT_UI_LABELS_PROBE ok")
	quit()
