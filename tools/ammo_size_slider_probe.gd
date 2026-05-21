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
	return int(capacity.get("bullet", 0)) + int(capacity.get("chemical", 0)) + int(capacity.get("laser", 0))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
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
	print("AMMO_SIZE_SLIDER_PROBE base=%d ranks=XS..XL ok" % base_total)
	quit()
