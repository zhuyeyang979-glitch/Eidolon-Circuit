extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_part_by_profile(main, profile: String) -> Dictionary:
	for raw_part in main._catalog_for("hero", "module"):
		if raw_part is Dictionary and String(Dictionary(raw_part).get("module_action_profile", "")) == profile:
			return Dictionary(raw_part)
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var two_link := _find_part_by_profile(main, "two_link_forward_snap")
	if two_link.is_empty():
		_fail("two_link_forward_snap module missing")
	for key in main.ACTION_MODULE_COMBAT_FIELD_KEYS:
		if two_link.has(String(key)):
			_fail("two-link module still owns combat field %s" % String(key))
	var physical_weapon_found := false
	for raw_part in main._catalog_for("hero", "muscle"):
		if not (raw_part is Dictionary):
			continue
		var part: Dictionary = raw_part
		if main._component_has_combat_volume(part, "muscle") and not main._component_is_torso(part) and main._part_counts_as_terminal_weapon(part, "muscle"):
			if main._part_damage_coeff(part, "muscle") > 0.0 and main._part_stiffness(part, "muscle") > 0.0:
				physical_weapon_found = true
				break
	if not physical_weapon_found:
		_fail("no physical weapon with runtime damage/stiffness context found")
	var gun_module := _find_part_by_profile(main, "gun_activate")
	if gun_module.is_empty():
		_fail("gun_activate module missing")
	for key in main.ACTION_MODULE_COMBAT_FIELD_KEYS:
		if gun_module.has(String(key)):
			_fail("gun activate module still owns combat field %s" % String(key))
	print("MODULE_DAMAGE_FROM_RUNTIME_CONTEXT_PROBE ok")
	quit()
