extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var result := main._repair_saved_unit4_for_training_dummy()
	if not bool(result.get("ok", false)):
		_fail("Unit4 training dummy repair failed: %s" % String(result.get("error", "")))
	var entry: Dictionary = result.get("entry", {}) if result.get("entry", {}) is Dictionary else {}
	var bp: Dictionary = Dictionary(entry.get("blueprint", {}))
	var note := main._training_blueprint_illegal_note(2, String(entry.get("role", "hero")), bp)
	if note != "":
		_fail("Repaired/current Unit4 should be training legal, got: %s" % note)
	print("UNIT4_TRAINING_DUMMY_REPAIR_PROBE ok repaired=%s path=%s" % [str(bool(result.get("repaired", false))), String(result.get("path", ""))])
	quit()
