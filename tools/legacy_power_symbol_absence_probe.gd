extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_no_legacy_keys(part: Dictionary, label: String) -> void:
	for key in ["power", "energy", "power_load", "engine_power", "required_power", "engine_torque", "engine_motion_scale", "normal_thrust", "boost_power", "thruster_momentum", "momentum_capacity", "load_capacity", "damage_unit_threshold", "reference_damage"]:
		if part.has(key):
			_fail("%s exposes legacy power key: %s" % [label, key])


func _assert_no_legacy_text(lines: Array, label: String) -> void:
	var text := ""
	for raw in lines:
		text += " %s" % String(raw)
	var lowered := text.to_lower()
	for term in ["engine_power", "required_power", "engine_torque", "normal_thrust", "boost_power", "thruster_momentum", "momentum cap", "damage unit", "load capacity", "载重", "动量承载", "推进动量"]:
		if lowered.find(term.to_lower()) >= 0:
			_fail("%s exposes legacy term: %s" % [label, term])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for slot_key in ["engine", "booster", "cooling", "limb_muscle", "muscle", "module"]:
		var catalog: Array = main._catalog_for("hero", slot_key)
		if catalog.is_empty():
			continue
		var part: Dictionary = main._selected_component("hero", slot_key, 0)
		_assert_no_legacy_keys(part, slot_key)
		_assert_no_legacy_text(main._hover_card_detail_lines(slot_key, part, {}, {}), slot_key)
	var stats := main._compute_unit_stats(0, "hero", 0, main._make_editor_blank_blueprint("hero"))
	_assert_no_legacy_keys(stats, "blank hero stats")
	_assert_no_legacy_text([main._format_unit_stats(stats)], "blank hero stats")
	print("LEGACY_POWER_SYMBOL_ABSENCE_PROBE ok")
	quit()
