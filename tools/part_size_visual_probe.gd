extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var card := MainScene.PartCatalogCardButton.new()
	var xs := {"name": "XS Probe", "size_class": "xs", "length": 0.12, "radius": 0.02, "mass": 1.0, "damage_type": "blunt"}
	var m := {"name": "M Probe", "size_class": "medium", "length": 0.7, "radius": 0.12, "mass": 12.0, "damage_type": "blunt"}
	var xl := {"name": "XL Probe", "size_class": "xl", "length": 2.6, "radius": 0.8, "mass": 180.0, "damage_type": "blunt"}
	card.set_card("muscle", xs, false, "zh", 0, "XS", "", "")
	var xs_scale := card._thumbnail_size_scale()
	card.set_card("muscle", m, false, "zh", 0, "M", "", "")
	var m_scale := card._thumbnail_size_scale()
	card.set_card("muscle", xl, false, "zh", 0, "XL", "", "")
	var xl_scale := card._thumbnail_size_scale()
	if not (xs_scale < m_scale and m_scale < xl_scale):
		_fail("Part thumbnail size scale is not strictly increasing: XS %.2f M %.2f XL %.2f." % [xs_scale, m_scale, xl_scale])
	if card._size_badge_text() != "XL":
		_fail("XL part did not produce XL size badge.")
	print("PART_SIZE_VISUAL_PROBE xs=%.2f m=%.2f xl=%.2f badge=%s" % [
		xs_scale,
		m_scale,
		xl_scale,
		card._size_badge_text(),
	])
	card.free()
	quit()
