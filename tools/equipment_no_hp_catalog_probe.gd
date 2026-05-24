extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_no_hp(main, slot_key: String, part: Dictionary) -> void:
	if part.has("hp") or part.has("health") or part.has("max_hp"):
		_fail("%s/%s still exposes HP" % [slot_key, String(part.get("name", "?"))])
	if main._component_has_combat_volume(part, slot_key):
		_fail("%s/%s is nonphysical equipment but reports combat volume" % [slot_key, String(part.get("name", "?"))])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for slot_key in ["engine", "booster", "cooling", "ammo"]:
		var catalog: Array = main._catalog_for("hero", slot_key)
		for raw_part in catalog:
			if raw_part is Dictionary:
				_assert_no_hp(main, slot_key, Dictionary(raw_part))
	for raw_part in main._catalog_for("hero", "muscle"):
		if not (raw_part is Dictionary):
			continue
		var part: Dictionary = raw_part
		if main._part_is_nonphysical_equipment_or_software("muscle", part):
			_assert_no_hp(main, "muscle", part)
	print("EQUIPMENT_NO_HP_CATALOG_PROBE ok")
	quit()
