extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.ui_language = "zh"
	var zh_name := main._part_group_name("software_muscle")
	if zh_name != "装备":
		_fail("Chinese equipment group label mismatch: %s" % zh_name)
	main.ui_language = "en"
	var en_name := main._part_group_name("software_muscle")
	if en_name != "EQUIPMENT":
		_fail("English equipment group label mismatch: %s" % en_name)
	var options: Array = main._part_filter_options_for_group("software_muscle")
	var keys := []
	for raw_option in options:
		if raw_option is Dictionary:
			keys.append(String(Dictionary(raw_option).get("key", "")))
	for required in ["engine", "booster", "cooling", "ammo", "shield_payload"]:
		if not keys.has(required):
			_fail("Equipment group missing filter: %s" % required)
	for forbidden in ["软肌肉", "SOFT-MUS"]:
		if zh_name.contains(forbidden) or en_name.contains(forbidden):
			_fail("Old soft-muscle label is still visible.")
	print("EQUIPMENT_GROUP_LABEL_PROBE ok zh=%s en=%s filters=%d" % [zh_name, en_name, keys.size()])
	quit()
