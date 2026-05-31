extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_ammo_part() -> Dictionary:
	for part in MainScene.COMMON_CATALOG["muscle"]:
		if part is Dictionary and (bool(Dictionary(part).get("ammo_slot_payload", false)) or String(Dictionary(part).get("material_class", "")) == "ammo_payload"):
			return Dictionary(part)
	return {}


func _capacity_total(capacity: Dictionary) -> int:
	var total := 0
	for ammo_type in MainScene.AMMO_TYPES:
		total += int(capacity.get(ammo_type, 0))
	return total


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_part_group_mode = "software_muscle"
	main.editor_part_filter_mode = "ammo"
	main._update_editor_ui()
	if main.editor_ammo_size_slider == null or not is_instance_valid(main.editor_ammo_size_slider):
		_fail("Ammo size slider control was not created.")
	if not main.editor_ammo_size_slider.visible:
		_fail("Ammo size slider should be visible when ammo filter is active.")
	if int(main.editor_ammo_size_slider.min_value) != 1 or int(main.editor_ammo_size_slider.max_value) != 5 or not is_equal_approx(float(main.editor_ammo_size_slider.step), 1.0):
		_fail("Ammo size slider must be a five-step XS..XL slider.")
	var ammo := _find_ammo_part()
	if ammo.is_empty():
		_fail("No ammo payload part found.")
	var base_cost := int(ammo.get("cost", 0))
	var base_mass := float(ammo.get("mass", 0.0))
	var base_total := _capacity_total(ammo.get("ammo_capacity", {}))
	for rank in range(1, 6):
		var variant := main._ammo_payload_variant(ammo, rank)
		var mult := int(pow(2.0, float(rank - 1)))
		if int(variant.get("cost", 0)) != base_cost * mult:
			_fail("Ammo cost multiplier failed for rank %d." % rank)
		if not is_equal_approx(float(variant.get("mass", 0.0)), base_mass * float(mult)):
			_fail("Ammo mass multiplier failed for rank %d." % rank)
		if _capacity_total(variant.get("ammo_capacity", {})) != base_total * mult:
			_fail("Ammo capacity multiplier failed for rank %d." % rank)
		if String(variant.get("ammo_size_tier", "")) != main._volume_rank_label(float(rank)):
			_fail("Ammo size tier label failed for rank %d." % rank)
	main.editor_ammo_size_slider.value = 5.0
	main._set_editor_ammo_size_rank_from_slider(float(main.editor_ammo_size_slider.value))
	if int(main.editor_ammo_size_rank) != 5:
		_fail("Ammo size slider did not update editor rank.")
	var display := main._catalog_display_part("muscle", ammo)
	if String(display.get("ammo_size_tier", "")) != "XL":
		_fail("Catalog display did not reflect ammo slider rank: %s." % String(display.get("ammo_size_tier", "")))
	print("AMMO_SIZE_SLIDER_PROBE base=%d ranks=XS..XL ui=ok" % base_total)
	quit()
