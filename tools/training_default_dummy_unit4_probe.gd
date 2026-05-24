extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var entry := main._training_dummy_unit4_entry()
	if entry.is_empty():
		_fail("Training dummy Unit4 entry is empty: %s" % main.training_import_error_note)
	var bp: Dictionary = Dictionary(entry.get("blueprint", {}))
	if String(bp.get("unit_name", "")) != "4":
		_fail("Default training dummy should be saved unit 4, got %s" % String(bp.get("unit_name", "")))
	var path := main._latest_training_dummy_unit_path()
	if path == "":
		_fail("Latest training dummy path should point to Unit4.")
	print("TRAINING_DEFAULT_DUMMY_UNIT4_PROBE ok path=%s" % path)
	quit()
