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


func _require_tag(part: Dictionary, tag: String) -> void:
	var tags: Array = Array(part.get("weapon_heat_tags", []))
	if not tags.has(tag):
		_fail("%s missing heat tag %s" % [String(part.get("name", "")), tag])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var light := _part(main, "HUMANOVA DUEL HEAT VEIN")
	var combo := _part(main, "GLACIER COMBO VENT")
	var missile := _part(main, "REDLINE SALVO HEAT SINK")
	var lung := _part(main, "COLOSSUS HEAT LUNG")
	if not failed:
		if float(light.get("mass", 0.0)) >= float(combo.get("mass", 0.0)):
			_fail("Light duelist cooler must be lighter than combo vent.")
		if float(combo.get("cooling", 0.0)) >= float(lung.get("cooling", 0.0)):
			_fail("Monster lung must out-cool combo vent.")
		if float(missile.get("heat_capacity", 0.0)) >= float(lung.get("heat_capacity", 0.0)):
			_fail("Monster lung must keep the largest heat buffer.")
		if float(combo.get("repeat_heat_relief", 0.0)) <= float(light.get("repeat_heat_relief", 0.0)):
			_fail("Combo vent must be the stronger repeat-action cooler.")
		_require_tag(light, "boost")
		_require_tag(combo, "repeat")
		_require_tag(missile, "missile")
		_require_tag(lung, "blunt")
	if failed:
		quit(1)
		return
	print("COOLING_GRADIENT_PROBE ok")
	quit()
