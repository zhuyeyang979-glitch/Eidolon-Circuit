extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _stat_labels(main, slot_key: String, part: Dictionary) -> Array:
	var labels: Array = []
	for raw_entry in main._hover_card_stat_entries(slot_key, part):
		if raw_entry is Dictionary:
			labels.append(String(Dictionary(raw_entry).get("label", "")))
	return labels


func _assert_no_hp_label(labels: Array, label_context: String) -> void:
	for label in labels:
		if String(label).to_lower() == "hp" or String(label).find("生命") >= 0:
			_fail("%s still shows HP label" % label_context)


func _assert_no_damage_label(labels: Array, label_context: String, allow_damage_resolve: bool = false) -> void:
	for label in labels:
		var label_text := String(label)
		if allow_damage_resolve and label_text in ["伤害结算", "Damage Resolve"]:
			continue
		if label_text.to_lower() == "damage" or label_text.find("伤害") >= 0:
			_fail("%s still shows damage label" % label_context)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for slot_key in ["engine", "booster", "cooling", "ammo", "special", "joint"]:
		for raw_part in main._catalog_for("hero", slot_key):
			if not (raw_part is Dictionary):
				continue
			var part: Dictionary = raw_part
			_assert_no_hp_label(_stat_labels(main, slot_key, part), "%s/%s" % [slot_key, String(part.get("name", "?"))])
	for raw_part in main._catalog_for("hero", "muscle"):
		if raw_part is Dictionary and main._part_is_nonphysical_equipment_or_software("muscle", Dictionary(raw_part)):
			_assert_no_hp_label(_stat_labels(main, "muscle", Dictionary(raw_part)), "muscle/%s" % String(Dictionary(raw_part).get("name", "?")))
	for raw_part in main._catalog_for("hero", "module"):
		if not (raw_part is Dictionary):
			continue
		var part: Dictionary = raw_part
		var labels := _stat_labels(main, "module", part)
		_assert_no_hp_label(labels, "module/%s" % String(part.get("name", "?")))
		_assert_no_damage_label(labels, "module/%s" % String(part.get("name", "?")), true)
	print("CATALOG_UI_NO_EQUIPMENT_HP_DAMAGE_PROBE ok")
	quit()
