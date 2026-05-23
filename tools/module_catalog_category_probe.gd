extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_module(main, needle: String) -> Dictionary:
	var catalog: Array = main._catalog_for("hero", "module")
	var lower := needle.to_lower()
	for raw_part in catalog:
		if raw_part is Dictionary:
			var part: Dictionary = raw_part
			if String(part.get("name", "")).to_lower().find(lower) >= 0:
				return part
	return {}


func _expect(main, needle: String, expected: String) -> void:
	var part := _find_module(main, needle)
	if part.is_empty():
		_fail("Missing module fixture: %s" % needle)
		return
	var actual: String = main._module_category_for_part(part)
	if actual != expected:
		_fail("Module %s category expected %s got %s." % [String(part.get("name", needle)), expected, actual])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	_expect(main, "TWO-LINK FORWARD SNAP", "melee")
	_expect(main, "BLADE ARC RETURN", "melee")
	_expect(main, "GAUNTLET EXTEND-SWING", "melee")
	_expect(main, "GUN ACTIVATE", "ranged")
	_expect(main, "PRISM BEAM", "ranged")
	_expect(main, "KESTREL MISSILE", "ranged")
	_expect(main, "WEB TETHER", "ranged")
	_expect(main, "GUNNER WRIST", "ranged")
	_expect(main, "HIJACK ROUTER", "other")
	_expect(main, "TETHER CAST", "other")
	print("MODULE_CATALOG_CATEGORY_PROBE ok")
	quit(0)
