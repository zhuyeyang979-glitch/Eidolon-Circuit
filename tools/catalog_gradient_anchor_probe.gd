extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part(main, slot_key: String, name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", slot_key, name)
	if index < 0:
		_fail("Missing anchor part: %s/%s" % [slot_key, name])
	return main._selected_component("hero", slot_key, index)


func _assert_live(main, slot_key: String, part: Dictionary) -> void:
	if main._part_is_catalog_frozen(slot_key, part):
		_fail("Anchor should be live: %s" % String(part.get("name", "")))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var duel := _part(main, "muscle", "HUMANOVA DUEL CORE")
	var midfield := _part(main, "muscle", "SYNTAX MIDFIELD CORE")
	var stage := _part(main, "muscle", "FOLD STAGE TORSO")
	for torso in [duel, midfield, stage]:
		_assert_live(main, "muscle", torso)
	if not (float(duel.get("mass", 0.0)) < float(midfield.get("mass", 0.0)) and float(midfield.get("mass", 0.0)) < float(stage.get("mass", 0.0))):
		_fail("Torso mass anchors are not monotonic.")
	var forearm := _part(main, "limb_muscle", "HUMANOVA FOREARM MYOMER")
	var thigh := _part(main, "limb_muscle", "HUMANOVA THIGH MYOMER")
	var colossus := _part(main, "limb_muscle", "COLOSSUS SINEW GIRDER")
	for limb in [forearm, thigh, colossus]:
		_assert_live(main, "limb_muscle", limb)
	if not (float(forearm.get("mass", 0.0)) < float(thigh.get("mass", 0.0)) and float(thigh.get("mass", 0.0)) < float(colossus.get("mass", 0.0))):
		_fail("Limb mass anchors are not monotonic.")
	for gun_name in [MainScene.STANDARD_SNIPER_NAME, MainScene.STANDARD_CHEMICAL_SPRAYER_NAME, MainScene.STANDARD_LASER_NAME, MainScene.STANDARD_MISSILE_NAME, MainScene.STANDARD_WEB_TETHER_GUN_NAME]:
		_assert_live(main, "muscle", _part(main, "muscle", gun_name))
	for slot_name in ["LIGHT FORMATION ENGINE", "GLACIER COMBO VENT", "BLUE XS CRUISE THRUSTER"]:
		var slot_key := "engine" if slot_name.find("ENGINE") >= 0 else ("cooling" if slot_name.find("VENT") >= 0 else "booster")
		_assert_live(main, slot_key, _part(main, slot_key, slot_name))
	var origin_pin := _part(main, "special", "ETHER: ORIGIN PIN")
	_assert_live(main, "special", origin_pin)
	print("CATALOG_GRADIENT_ANCHOR_PROBE ok")
	quit()
