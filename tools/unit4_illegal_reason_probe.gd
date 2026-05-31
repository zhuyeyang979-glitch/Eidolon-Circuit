extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var entry: Dictionary = main._latest_saved_unit_named("4")
	if entry.is_empty():
		_fail("Saved unit 4 is missing.")
	var role_key := String(entry.get("role", "hero"))
	var unit_bp: Dictionary = Dictionary(entry.get("blueprint", {}))
	var note := main._training_blueprint_illegal_note(1, role_key, unit_bp)
	var stats := main._compute_unit_stats(1, role_key, -1, unit_bp)
	var engine_note := String(stats.get("engine_momentum_note", ""))
	if note != "":
		_fail("Unit 4 should be legal after training dummy repair, got: %s" % note)
	if engine_note.contains("INVALID"):
		_fail("Unit 4 engine note should not report an invalid budget, got: %s" % engine_note)
	print("UNIT4_ILLEGAL_REASON_PROBE ok legal engine='%s'" % engine_note)
	quit()
