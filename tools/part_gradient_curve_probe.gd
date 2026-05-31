extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _gradient_value(main, slot_key: String, part: Dictionary) -> float:
	match slot_key:
		"engine":
			return main._engine_momentum_output_for_part(part)
		"booster":
			return main._thruster_drive_allocation_max_for_part(part) + main._thruster_boost_brake_allocation_max_for_part(part)
		"cooling":
			return main._cooling_heat_capacity_for_part(part)
		"limb_muscle":
			return main._limb_momentum_max_for_part(part, slot_key)
		"muscle":
			if main._component_is_torso(part):
				return float(part.get("mass", 0.0))
			if main._terminal_weapon_kind_for_part(part, "muscle") == "ranged":
				return main._projectile_momentum_for_event(part.duplicate(true))
			return main._part_stiffness(part, slot_key)
	return float(part.get("cost", 0.0))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var grouped := {}
	var checked := 0
	for slot_key in ["engine", "booster", "cooling", "limb_muscle", "muscle", "module"]:
		var catalog: Array = main._catalog_for("hero", slot_key)
		for i in range(catalog.size()):
			var part: Dictionary = main._selected_component("hero", slot_key, i)
			if main._part_is_catalog_frozen(slot_key, part):
				continue
			var spec: Dictionary = main._part_gradient_spec(slot_key, part)
			for field in MainScene.PART_GRADIENT_SPEC_FIELDS:
				if not spec.has(String(field)):
					_fail("%s/%s missing gradient field %s" % [slot_key, String(part.get("name", "?")), String(field)])
			if String(spec.get("rank_label", "")) == "":
				_fail("%s/%s has empty gradient rank." % [slot_key, String(part.get("name", "?"))])
			if Array(spec.get("tradeoff_tags", [])).is_empty():
				_fail("%s/%s has empty gradient tradeoff tags." % [slot_key, String(part.get("name", "?"))])
			if slot_key in ["engine", "booster", "cooling", "limb_muscle"]:
				var key := "%s|%s" % [slot_key, String(spec.get("family", ""))]
				if not grouped.has(key):
					grouped[key] = {}
				var rank := int(spec.get("rank", 1))
				var value := _gradient_value(main, slot_key, part)
				grouped[key][rank] = maxf(float(grouped[key].get(rank, 0.0)), value)
			checked += 1
	for key in grouped.keys():
		var by_rank: Dictionary = grouped[key]
		var previous := 0.0
		for rank in range(1, 6):
			if not by_rank.has(rank):
				continue
			var value := float(by_rank[rank])
			if previous > 0.0 and value + 0.01 < previous * 0.62:
				_fail("%s rank %d drops too sharply: %.2f after %.2f" % [String(key), rank, value, previous])
			previous = maxf(previous, value)
	if checked <= 0:
		_fail("No live parts checked.")
	if failed:
		quit(1)
		return
	print("PART_GRADIENT_CURVE_PROBE ok checked=%d families=%d" % [checked, grouped.size()])
	quit()
