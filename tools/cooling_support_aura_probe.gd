extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _fighter(name: String, owner: int, stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": name, "owner_id": owner, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var support = _fighter("COOL_SUPPORT", 1, {"support_kind": "cooling", "support_rate": 30.0, "coolant_boost": 30.0})
	var target = _fighter("HOT_HERO", 1, {"heat_capacity": 100.0, "cooling": 0.0, "overheat_clear_ratio": 0.5})
	target.heat = 80.0
	target.overheated = true
	main._apply_support_to_target(support, target, 1.0)
	if float(target.heat) >= 51.0:
		_fail("Cooling support should reduce allied heat by its support rate.")
	target.heat = 48.0
	target.overheated = true
	main._apply_support_to_target(support, target, 0.05)
	if target.overheated:
		_fail("Cooling support should honor target overheat clear ratio.")
	var fin_index: int = main._component_index_by_exact_name("hero", "muscle", "COOLANT AURA FIN")
	if fin_index < 0:
		_fail("Missing COOLANT AURA FIN.")
	else:
		var fin := main._selected_component("hero", "muscle", fin_index)
		if not bool(fin.get("is_coolant_field", false)) or float(fin.get("coolant_boost", 0.0)) < 22.0:
			_fail("COOLANT AURA FIN should be a small team coolant field.")
	if failed:
		quit(1)
		return
	print("COOLING_SUPPORT_AURA_PROBE ok heat=%.1f" % float(target.heat))
	quit()
