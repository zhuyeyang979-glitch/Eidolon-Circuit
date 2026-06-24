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
	var expected_zh_groups := {
		"torso": "核心",
		"limb": "连接件",
		"barrier_panel": "功能模块",
		"software_muscle": "软硬件",
	}
	for group_key in expected_zh_groups:
		var label := main._part_group_name(group_key)
		if label != String(expected_zh_groups[group_key]):
			_fail("Chinese group label mismatch for %s: %s" % [group_key, label])
	var zh_name := main._part_group_name("software_muscle")
	if zh_name != "软硬件":
		_fail("Chinese hybrid group label mismatch: %s" % zh_name)
	main.ui_language = "en"
	var expected_en_groups := {
		"torso": "CORE",
		"limb": "CONNECTOR",
		"barrier_panel": "FUNCTION",
		"software_muscle": "HYBRID",
	}
	for group_key in expected_en_groups:
		var label := main._part_group_name(group_key)
		if label != String(expected_en_groups[group_key]):
			_fail("English group label mismatch for %s: %s" % [group_key, label])
	var en_name := main._part_group_name("software_muscle")
	if en_name != "HYBRID":
		_fail("English hybrid group label mismatch: %s" % en_name)
	var options: Array = main._part_filter_options_for_group("software_muscle")
	var keys := []
	var booster_label := ""
	for raw_option in options:
		if raw_option is Dictionary:
			var option := Dictionary(raw_option)
			var key := String(option.get("key", ""))
			keys.append(key)
			if key == "booster":
				booster_label = String(option.get("en", ""))
	for required in ["engine", "booster", "cooling", "ammo", "shield_payload"]:
		if not keys.has(required):
			_fail("Hybrid group missing filter: %s" % required)
	if booster_label != "THRUSTER":
		_fail("Booster compatibility key must display as THRUSTER: %s" % booster_label)
	for forbidden in ["软肌肉", "SOFT-MUS", "装备", "EQUIPMENT"]:
		if zh_name.contains(forbidden) or en_name.contains(forbidden):
			_fail("Old soft-muscle label is still visible.")
	print("EQUIPMENT_GROUP_LABEL_PROBE ok zh=%s en=%s filters=%d" % [zh_name, en_name, keys.size()])
	quit()
