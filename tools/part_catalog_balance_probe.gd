extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _check_slot(main, role_key: String, slot_key: String) -> void:
	var catalog: Array = main._catalog_for(role_key, slot_key)
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component(role_key, slot_key, i)
		if not main._component_has_combat_volume(part, slot_key):
			continue
		var name := String(part.get("name", "%s:%d" % [slot_key, i]))
		for field in ["mass", "hp", "stiffness_momentum", "damage_coeff", "break_coeff", "size_tier", "contact_shape_kind"]:
			if not part.has(field):
				_fail("%s missing combat field %s" % [name, field])
		if float(part.get("stiffness_momentum", 0.0)) <= 0.0:
			_fail("%s has non-positive stiffness." % name)
		if float(part.get("damage_coeff", 0.0)) <= 0.0:
			_fail("%s has non-positive damage_coeff." % name)
		if float(part.get("break_coeff", 0.0)) <= 0.0:
			_fail("%s has non-positive break_coeff." % name)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for slot_key in ["muscle", "limb_muscle", "barrier"]:
		_check_slot(main, "hero", slot_key)
	print("PART_CATALOG_BALANCE_PROBE ok")
	quit()
