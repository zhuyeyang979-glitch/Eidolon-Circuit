extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _part(main, name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", "cooling", name)
	if index < 0:
		_fail("Missing cooling part: %s" % name)
		return {}
	return main._selected_component("hero", "cooling", index)


func _assert_fit(part: Dictionary, tag: String, relief_key: String) -> void:
	if not Array(part.get("weapon_heat_tags", [])).has(tag):
		_fail("%s missing tag %s" % [String(part.get("name", "")), tag])
	if float(part.get(relief_key, 0.0)) <= 0.0:
		_fail("%s missing relief %s" % [String(part.get("name", "")), relief_key])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	_assert_fit(_part(main, "LONGSIGHT PRISM CHILLER"), "laser", "laser_heat_relief")
	_assert_fit(_part(main, "CAUSTIC SPRAY RADIATOR"), "chemical", "chemical_heat_relief")
	_assert_fit(_part(main, "REDLINE SALVO HEAT SINK"), "missile", "missile_heat_relief")
	_assert_fit(_part(main, "COINRUN FLOW COOLER"), "boost", "boost_heat_relief")
	var laser := _part(main, "LONGSIGHT PRISM CHILLER")
	if Array(laser.get("weapon_heat_tags", [])).has("missile"):
		_fail("Laser chiller should not also advertise missile fit.")
	if failed:
		quit(1)
		return
	print("COOLING_WEAPON_FIT_PROBE ok")
	quit()
