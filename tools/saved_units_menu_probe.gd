extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if not MainScene.MENU_ITEMS.has("已保存单位"):
		_fail("Main menu should expose 已保存单位.")
	main._activate_menu_item(1)
	if main.game_state != MainScene.STATE_SAVED_UNITS:
		_fail("Saved Units menu item should open the saved-unit library state.")
	if main.saved_units_layer == null or not main.saved_units_layer.visible:
		_fail("Saved Units layer should be visible after opening.")
	if main.saved_unit_buttons.size() < 1 or main.saved_unit_detail_view == null:
		_fail("Saved Units library should have cards and a detail panel.")
	print("SAVED_UNITS_MENU_PROBE ok buttons=%d" % main.saved_unit_buttons.size())
	quit()
