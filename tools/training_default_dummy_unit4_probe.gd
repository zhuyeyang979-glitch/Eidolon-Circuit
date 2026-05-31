extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var entry := main._training_dummy_unit2_entry()
	if entry.is_empty():
		_fail("Training ball dummy entry is empty: %s" % main.training_import_error_note)
	var bp: Dictionary = Dictionary(entry.get("blueprint", {}))
	if not bool(bp.get("training_ball_dummy", false)):
		_fail("Default training dummy should be the dedicated ball dummy.")
	var path := main._latest_training_dummy_unit_path()
	if path != "":
		_fail("Default training dummy should not require a saved Unit4 path, got %s" % path)
	print("TRAINING_DEFAULT_DUMMY_UNIT4_PROBE ok ball_radius=%.2f" % float(bp.get("training_dummy_radius_m", 0.0)))
	quit()
