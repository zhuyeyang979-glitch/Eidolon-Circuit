extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _option_keys(options: Array) -> Array:
	var keys: Array = []
	for option in options:
		if option is Dictionary:
			keys.append(String(Dictionary(option).get("key", "")))
	return keys


func _entry_labels(entries: Array) -> Array:
	var labels: Array = []
	for entry in entries:
		if entry is Dictionary:
			labels.append(String(Dictionary(entry).get("label", "")))
	return labels


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var expected_groups := ["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"]
	if MainScene.EDITOR_PART_GROUP_ORDER != expected_groups:
		_fail("Part library first layer mismatch, got %s." % str(MainScene.EDITOR_PART_GROUP_ORDER))
	if MainScene.EDITOR_PART_GROUP_ORDER.has("joint") or MainScene.TOPOLOGY_PART_SLOTS.has("joint"):
		_fail("Independent joint must not be visible/placeable.")
	var torso_keys := _option_keys(main._part_filter_options_for_group("torso"))
	for required in ["connector_torso", "connector_brain"]:
		if not torso_keys.has(required):
			_fail("Torso filter missing %s." % required)
	var limb_keys := _option_keys(main._part_filter_options_for_group("limb"))
	if limb_keys != ["connector_limb"]:
		_fail("Limb filter mismatch: %s." % str(limb_keys))
	var weapon_keys := _option_keys(main._part_filter_options_for_group("terminal_weapon"))
	for required in ["terminal", "terminal_ranged", "terminal_melee"]:
		if not weapon_keys.has(required):
			_fail("Weapon filter missing %s." % required)
	var barrier_keys := _option_keys(main._part_filter_options_for_group("barrier_panel"))
	if not barrier_keys.has("barrier_muscle"):
		_fail("Barrier panel filter missing barrier_muscle.")
	var software_muscle_keys := _option_keys(main._part_filter_options_for_group("software_muscle"))
	for required in ["engine", "booster", "cooling", "ammo", "shield_payload"]:
		if not software_muscle_keys.has(required):
			_fail("Software-muscle filter missing %s." % required)
	var software_keys := _option_keys(main._part_filter_options_for_group("software"))
	for required in ["soul", "code", "ether", "module"]:
		if not software_keys.has(required):
			_fail("Software filter missing %s." % required)
	var stats: Dictionary = main._editor_current_stats()
	var summary: Dictionary = main._team_summary(1)
	var entries: Array = main._editor_stats_entries(stats, {}, summary, {}, {})
	var labels := _entry_labels(entries)
	for required_label in ["当前画布造价", "动力分配", "热管理平衡", "机内插件槽 0/0", "软件槽 0/0"]:
		if not labels.has(required_label):
			_fail("Dashboard missing %s in labels %s." % [required_label, str(labels)])
	if labels.has("全队总价"):
		_fail("Unit-first blank canvas should not show team total in the default dashboard.")
	print("PART_LIBRARY_UI_PROBE groups=%s weapon=%d software_muscle=%d software=%d dashboard=%d" % [str(MainScene.EDITOR_PART_GROUP_ORDER), weapon_keys.size(), software_muscle_keys.size(), software_keys.size(), entries.size()])
	quit()
