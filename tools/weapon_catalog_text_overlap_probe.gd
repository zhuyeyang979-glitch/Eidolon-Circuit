extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _filter_index(main, key: String) -> int:
	var options: Array = main._part_filter_options_for_group(main.editor_part_group_mode)
	for i in range(options.size()):
		if options[i] is Dictionary and String(Dictionary(options[i]).get("key", "")) == key:
			return i
	return -1


func _check_visible_weapon_cards(main, label: String) -> void:
	main._update_editor_catalog_buttons(main.ROLE_ORDER[main.editor_role_index], main._editor_current_blueprint())
	for raw_button in main.editor_catalog_buttons:
		if raw_button == null or not (raw_button is MainScene.PartCatalogCardButton):
			continue
		var button: MainScene.PartCatalogCardButton = raw_button
		if not button.visible:
			continue
		var line_a := String(button.data_line_a)
		var line_b := String(button.data_line_b)
		if line_a.length() > 18:
			_fail("%s line A is too long for retained card: %s" % [label, line_a])
			return
		if line_b.length() > 22:
			_fail("%s line B is too long for retained card: %s" % [label, line_b])
			return
		if line_a.contains("missile_launcher") or line_a.contains("grenade_launcher") or line_a.contains("Weapon >"):
			_fail("%s line A contains full category text: %s" % [label, line_a])
			return


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_panel_mode = "parts"
	main._select_editor_part_group("terminal_weapon")
	main._update_editor_ui(true)
	_check_visible_weapon_cards(main, "all")
	var melee_index := _filter_index(main, "weapon_melee")
	if melee_index >= 0:
		main._select_editor_part_filter(melee_index)
		_check_visible_weapon_cards(main, "melee")
	var gun_index := _filter_index(main, "weapon_gun")
	if gun_index >= 0:
		main._select_editor_part_filter(gun_index)
		_check_visible_weapon_cards(main, "gun")
	print("WEAPON_CATALOG_TEXT_OVERLAP_PROBE ok filters=all/melee/gun")
	quit(0)
