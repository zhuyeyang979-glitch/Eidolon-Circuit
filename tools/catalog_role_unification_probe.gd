extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part(main, slot_key: String, name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", slot_key, name)
	if index < 0:
		_fail("Missing catalog part: %s/%s" % [slot_key, name])
		return {}
	return main._selected_component("hero", slot_key, index)


func _require_meta(part: Dictionary, role: String, category_prefix: String, label: String) -> void:
	if String(part.get("catalog_role", "")) != role:
		_fail("%s catalog_role expected %s, got %s" % [label, role, String(part.get("catalog_role", ""))])
	if not String(part.get("part_category", "")).begins_with(category_prefix):
		_fail("%s part_category expected prefix %s, got %s" % [label, category_prefix, String(part.get("part_category", ""))])
	if not part.has("catalog_lifecycle"):
		_fail("%s missing catalog_lifecycle metadata." % label)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var torso := _part(main, "muscle", "SYNTAX MIDFIELD CORE")
	_require_meta(torso, "torso", "torso", "torso")
	var laser := _part(main, "muscle", MainScene.STANDARD_LASER_NAME)
	_require_meta(laser, "gun", "gun:laser_gun", "standard laser")
	if main._part_is_catalog_frozen("muscle", laser):
		_fail("Standard laser should remain live after metadata normalization.")
	var old_laser := _part(main, "muscle", "LASER EMITTER GUN")
	_require_meta(old_laser, "gun", "gun:", "old laser")
	if not main._part_is_catalog_frozen("muscle", old_laser):
		_fail("Old laser should remain frozen.")
	if String(old_laser.get("future_dev_tag", "")) == "":
		_fail("Frozen old laser should expose future_dev_tag metadata.")
	var engine := _part(main, "engine", "SPARK SWARM LITE ENGINE")
	_require_meta(engine, "engine", "engine", "engine")
	var display := main._catalog_display_part("cooling", _part(main, "cooling", "GLACIER COMBO VENT"))
	_require_meta(display, "cooling", "cooling", "cooling display")
	main.ui_language = MainScene.UI_LANGUAGE_EN
	var lines: Array = main._catalog_card_data_lines("cooling", display)
	if not String(lines[0]).contains("POOL") or String(lines[0]).contains("CAP"):
		_fail("English cooling catalog card should use POOL, not CAP: %s" % String(lines[0]))
	var detail_lines: Array = main._hover_card_detail_lines("muscle", laser, {}, {})
	for line in detail_lines:
		var text := String(line)
		for forbidden in ["Compat view", "projectile mass", "collision speed"]:
			if text.find(forbidden) >= 0:
				_fail("Hover detail kept old unreachable engineering text: %s" % forbidden)
	print("CATALOG_ROLE_UNIFICATION_PROBE ok")
	quit()
