extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part_index(main, slot_key: String, name_fragment: String) -> int:
	for i in range(main._catalog_for("hero", slot_key).size()):
		var part: Dictionary = main._selected_component("hero", slot_key, i)
		if String(part.get("name", "")).findn(name_fragment) >= 0:
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var soul_index := _part_index(main, "special", "FIRST EDGE ECHO")
	var missile_index := _part_index(main, "muscle", "REDLINE KESTREL MISSILE POD")
	if min(soul_index, missile_index) < 0:
		_fail("Missing first soul or missile mismatch sample.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	unit_bp.erase("custom_topology")
	unit_bp.erase("slot_payloads")
	unit_bp.erase("module_bindings")
	unit_bp["blank_canvas"] = false
	unit_bp["special"] = soul_index
	unit_bp["muscle"] = missile_index
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	if bool(stats.get("soul_oath_active", false)):
		_fail("Missile/pure-ranged mismatch should not activate duelist oath.")
	if float(stats.get("soul_heat_capacity", 0.0)) < 60.0:
		_fail("Mismatch should still keep the baseline soul heat slot.")
	if String(stats.get("soul_oath_reason", "")) in ["", "active"]:
		_fail("Mismatch should expose an inactive reason.")
	if int(stats.get("normal_damage", 0)) > 40 or int(stats.get("active_damage", 0)) > 60:
		_fail("Inactive first soul should not add old unconditional damage soup.")
	print("SOUL_OATH_MISMATCH_PROBE ok")
	quit()
