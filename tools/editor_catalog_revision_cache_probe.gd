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
	main.editor_panel_mode = "parts"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	var role_key: String = MainScene.ROLE_ORDER[main.editor_role_index]
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main.editor_catalog_revision_skip_count = 0
	main._update_editor_catalog_buttons(role_key, unit_bp)
	var first_key := String(main.editor_catalog_buttons_revision_key)
	main._update_editor_catalog_buttons(role_key, unit_bp)
	if int(main.editor_catalog_revision_skip_count) <= 0:
		_fail("Repeated catalog update did not hit revision cache.")
		return
	if first_key == "":
		_fail("Catalog revision key was not recorded.")
		return
	print("EDITOR_CATALOG_REVISION_CACHE_PROBE ok skips=%d" % int(main.editor_catalog_revision_skip_count))
	quit(0)
