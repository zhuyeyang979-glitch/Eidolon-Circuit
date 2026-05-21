extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_no_old_terms(text: String, label: String) -> void:
	var lowered := text.to_lower()
	for forbidden in ["damage unit", "momentum cap", "load capacity", "damage threshold", "reference damage", "boost_power", "normal_thrust", "boost cone", "booster size", "boost style", "boost flame"]:
		if lowered.find(forbidden) >= 0:
			_fail("%s still exposes old combat term: %s" % [label, forbidden])


func _assert_has_new_terms(entries: Array, label: String) -> void:
	var joined := ""
	for raw in entries:
		if raw is Dictionary:
			joined += " %s" % String(Dictionary(raw).get("label", ""))
	var lowered := joined.to_lower()
	if lowered.find("stiffness") < 0 and joined.find("刚度") < 0:
		_fail("%s does not show stiffness in hover stats: %s" % [label, joined])
	if lowered.find("damage coeff") < 0 and joined.find("伤害系数") < 0:
		_fail("%s does not show damage coefficient in hover stats: %s" % [label, joined])
	if lowered.find("break coeff") < 0 and joined.find("破防系数") < 0:
		_fail("%s does not show break coefficient in hover stats: %s" % [label, joined])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var torso: Dictionary = main._selected_component("hero", "muscle", 0)
	var limb: Dictionary = main._selected_component("hero", "limb_muscle", 0)
	var terminal: Dictionary = {}
	var terminal_catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(terminal_catalog.size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if bool(part.get("terminal_weapon", false)):
			terminal = part
			break
	if terminal.is_empty():
		_fail("Could not find a terminal weapon for UI term probe.")
	_assert_has_new_terms(main._hover_card_stat_entries("muscle", torso), "torso")
	_assert_has_new_terms(main._hover_card_stat_entries("limb_muscle", limb), "limb")
	_assert_has_new_terms(main._hover_card_stat_entries("muscle", terminal), "terminal")
	for line in main._hover_card_detail_lines("muscle", torso, {}, {}):
		_assert_no_old_terms(String(line), "torso detail")
	for line in main._hover_card_detail_lines("limb_muscle", limb, {}, {}):
		_assert_no_old_terms(String(line), "limb detail")
	var booster: Dictionary = main._selected_component("hero", "booster", 0)
	var booster_entries := main._hover_card_stat_entries("booster", booster)
	var booster_labels := ""
	for raw in booster_entries:
		if raw is Dictionary:
			booster_labels += " %s" % String(Dictionary(raw).get("label", ""))
	if booster_labels.find("推进动量") < 0 and booster_labels.to_lower().find("move mom") < 0:
		_fail("Booster hover does not expose explicit thruster momentum: %s" % booster_labels)
	for line in main._hover_card_detail_lines("booster", booster, {}, {}):
		_assert_no_old_terms(String(line), "booster detail")
	print("CATALOG_UI_TERMS_PROBE ok")
	quit()
