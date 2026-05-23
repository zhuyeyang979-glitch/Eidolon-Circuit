extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const PartArt := preload("res://scripts/part_art.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_catalog_part(main, slot_key: String) -> Dictionary:
	var catalog: Array = main._catalog_for("hero", slot_key)
	if catalog.is_empty():
		return {}
	return catalog[0]


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var slots := ["muscle", "limb_muscle", "booster", "engine", "cooling", "module"]
	var labels := []
	for slot_key in slots:
		var part := _first_catalog_part(main, slot_key)
		if part.is_empty():
			continue
		var badge := main._catalog_part_size_badge(slot_key, part)
		if badge == "":
			_fail("Missing catalog size badge for slot %s part %s" % [slot_key, String(part.get("name", ""))])
			return
		if badge != PartArt.normalized_size_tier(part):
			_fail("Badge helper disagrees with PartArt for %s: %s vs %s" % [slot_key, badge, PartArt.normalized_size_tier(part)])
			return
		var card := MainScene.PartCatalogCardButton.new()
		card.set_card(slot_key, part, false, "zh", 0, String(part.get("name", "")), "", "")
		if card._size_badge_text() == "":
			_fail("PartCatalogCardButton badge missing for %s" % slot_key)
			return
		var icon := MainScene.PartPreviewIconView.new()
		icon.size = Vector2(120, 90)
		icon.set_preview(slot_key, part, false)
		if PartArt.normalized_size_tier(icon.part) == "":
			_fail("Hover/preview icon size tier missing for %s" % slot_key)
			return
		card.free()
		icon.free()
		labels.append("%s:%s" % [slot_key, badge])
	print("CATALOG_CARD_SIZE_BADGE_PROBE ok badges=%s" % ",".join(labels))
	quit(0)
