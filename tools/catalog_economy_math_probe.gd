extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _median(values: Array) -> float:
	if values.is_empty():
		return 0.0
	values.sort()
	var mid := values.size() / 2
	if values.size() % 2 == 1:
		return float(values[mid])
	return (float(values[mid - 1]) + float(values[mid])) * 0.5


func _slot_summary(main, slot_key: String) -> Dictionary:
	var costs: Array = []
	var masses: Array = []
	var hp_values: Array = []
	var families := {}
	var live_count := 0
	var frozen_count := 0
	var catalog: Array = main._catalog_for("hero", slot_key)
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", slot_key, i)
		var name := String(part.get("name", "%s:%d" % [slot_key, i]))
		if main._part_is_catalog_frozen(slot_key, part):
			frozen_count += 1
			continue
		live_count += 1
		var cost := float(part.get("cost", 0.0))
		var mass := float(part.get("mass", 0.0))
		var hp := float(part.get("hp", 0.0))
		if cost < 0.0 or mass < 0.0 or hp < 0.0:
			_fail("%s has negative economy field." % name)
		costs.append(cost)
		masses.append(mass)
		hp_values.append(hp)
		if main._component_has_combat_volume(part, slot_key):
			for field in ["size_tier", "contact_shape_kind", "stiffness_momentum", "damage_coeff", "break_coeff"]:
				if not part.has(field):
					_fail("%s live combat part missing %s." % [name, field])
		if slot_key in ["engine", "cooling", "booster"] and not part.has("slot_volume_tier"):
			_fail("%s live plugin missing slot_volume_tier." % name)
		var family := String(part.get("gradient_family", part.get("weapon_family", part.get("engine_family", part.get("cooling_profile", part.get("thruster_family", part.get("gun_kind", part.get("kind", slot_key))))))))
		if family.strip_edges() == "":
			family = slot_key
		families[family] = true
	if live_count <= 0:
		_fail("%s has no live catalog entries." % slot_key)
	return {
		"live": live_count,
		"frozen": frozen_count,
		"families": families.size(),
		"cost_median": _median(costs),
		"mass_median": _median(masses),
		"hp_median": _median(hp_values),
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var summaries := {}
	for slot_key in ["joint", "limb_muscle", "muscle", "engine", "cooling", "booster", "module", "special"]:
		summaries[slot_key] = _slot_summary(main, slot_key)
	print("CATALOG_ECONOMY_MATH_PROBE %s" % str(summaries))
	quit()
