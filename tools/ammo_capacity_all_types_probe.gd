extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var capacity := {"bullet": 1, "laser": 2, "chemical": 3, "explosive": 4, "web": 5}
	if main._ammo_capacity_total(capacity) != 15:
		_fail("Ammo capacity total must include bullet/laser/chemical/explosive/web.")
	var scaled := main._scaled_ammo_capacity(capacity, 8)
	for ammo_type in MainScene.AMMO_TYPES:
		if not scaled.has(ammo_type):
			_fail("Scaled capacity missing ammo type %s." % ammo_type)
		if int(scaled.get(ammo_type, 0)) != int(capacity.get(ammo_type, 0)) * 8:
			_fail("Scaled capacity mismatch for %s." % ammo_type)
	if main._ammo_capacity_total(scaled) != 120:
		_fail("Scaled ammo total should include all ammo types.")
	var found_types := {}
	for raw_part in MainScene.COMMON_CATALOG["muscle"]:
		if not (raw_part is Dictionary):
			continue
		var part: Dictionary = raw_part
		if not main._part_is_ammo_payload(part):
			continue
		var variant := main._ammo_payload_variant(part, "XL")
		var caps: Dictionary = variant.get("ammo_capacity", {})
		for ammo_type in MainScene.AMMO_TYPES:
			if not caps.has(ammo_type):
				_fail("Ammo variant for %s missing key %s." % [String(part.get("name", "")), ammo_type])
			if int(caps.get(ammo_type, 0)) > 0:
				found_types[ammo_type] = true
	if not found_types.has("explosive") or not found_types.has("web"):
		_fail("Live ammo payload catalog must include explosive and web ammo bays.")
	print("AMMO_CAPACITY_ALL_TYPES_PROBE types=%s ok" % str(found_types.keys()))
	quit()
