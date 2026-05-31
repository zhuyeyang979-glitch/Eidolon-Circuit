extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if not MainScene.MENU_ITEMS.has("单位编辑"):
		_fail("Main menu should expose 单位编辑.")
	if MainScene.MENU_ITEMS.has("队伍编辑"):
		_fail("Main menu should not expose 队伍编辑.")
	if not MainScene.MENU_ITEMS_EN.has("UNIT EDIT"):
		_fail("English main menu should expose UNIT EDIT.")
	main._show_editor(true)
	var title = main.editor_layer.find_child("EditorTitle", true, false)
	if title != null and title is CanvasItem and bool(title.visible):
		_fail("Unit Edit page should not show the old large editor title.")
	print("UNIT_EDITOR_RENAME_PROBE ok")
	quit()
