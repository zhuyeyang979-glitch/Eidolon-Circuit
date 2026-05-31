extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _family_parts(main, family: String) -> Array:
	var result: Array = []
	var catalog: Array = main._catalog_for("hero", "engine")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "engine", i)
		if String(part.get("engine_family", "")).to_lower() == family:
			result.append(part)
	return result


func _family_has_tag(parts: Array, tag: String) -> bool:
	for raw in parts:
		var part: Dictionary = raw
		if Array(part.get("engine_weapon_tags", [])).has(tag):
			return true
	return false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if not _family_has_tag(_family_parts(main, "melee_drive"), "heavy_melee"):
		_fail("melee_drive engines should advertise heavy melee fit.")
	if not _family_has_tag(_family_parts(main, "ranged_control"), "missile"):
		_fail("ranged_control engines should advertise missile/fire-control fit.")
	if not _family_has_tag(_family_parts(main, "booster_core"), "route"):
		_fail("booster_core engines should advertise route/chase fit.")
	if not _family_has_tag(_family_parts(main, "siege_reactor"), "support"):
		_fail("siege_reactor engines should advertise support load fit.")
	for family in ["balanced", "melee_drive", "ranged_control", "booster_core", "swarm_lite", "siege_reactor"]:
		for raw in _family_parts(main, family):
			var part: Dictionary = raw
			if String(part.get("engine_team_role", "")) == "" or String(part.get("engine_heat_profile", "")) == "":
				_fail("%s lacks team role or heat profile." % String(part.get("name", "")))
	if failed:
		quit(1)
		return
	print("ENGINE_WEAPON_FIT_PROBE ok")
	quit()
