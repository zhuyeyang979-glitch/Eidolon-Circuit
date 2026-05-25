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
	main.editor_part_group_mode = "software_muscle"
	main.editor_part_filter_mode = "ammo"
	main._set_editor_ammo_size_rank(3)
	main._update_editor_ui()
	if main.editor_ammo_size_slider == null or not is_instance_valid(main.editor_ammo_size_slider):
		_fail("Ammo size slider missing.")
	if not main.editor_ammo_size_slider.visible:
		_fail("Ammo size slider should be visible in ammo install filter.")
	if int(roundf(float(main.editor_ammo_size_slider.value))) != 3:
		_fail("Ammo size slider value should track editor rank.")
	if main.editor_ammo_size_title_label == null or String(main.editor_ammo_size_title_label.text) == "":
		_fail("Ammo size title label missing text.")
	if main.editor_ammo_size_value_label == null or String(main.editor_ammo_size_value_label.text) != "M x4":
		_fail("Ammo size value label should show selected M x4 tier.")
	if main.editor_ammo_size_tick_labels.size() != 5:
		_fail("Ammo size slider must expose five visible tick labels.")
	var expected := ["XS", "S", "M", "L", "XL"]
	for i in range(expected.size()):
		var tick = main.editor_ammo_size_tick_labels[i]
		if tick == null or not is_instance_valid(tick) or not tick.visible:
			_fail("Ammo size tick %d is not visible." % i)
		if String(tick.text) != String(expected[i]):
			_fail("Ammo size tick %d mismatch: %s." % [i, String(tick.text)])
	var entries: Array = main._editor_catalog_raw_entries("hero", "muscle")
	if entries.is_empty():
		_fail("Ammo filter should show live ammo entries.")
	for entry in entries:
		if not (entry is Dictionary):
			continue
		var display: Dictionary = Dictionary(entry).get("display_part", {})
		if String(display.get("ammo_size_tier", "")) != "M":
			_fail("Ammo catalog display entry did not use selected slider tier: %s." % str(display))
	print("AMMO_SIZE_UI_PROBE entries=%d tier=M ok" % entries.size())
	quit()
