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
	var stats := main._compute_unit_stats(1, role_key, -1, unit_bp)
	var engine := float(stats.get("engine_momentum_output", 0.0))
	var thruster := float(stats.get("thruster_allocated_momentum", 0.0))
	var limb := float(stats.get("bound_limb_allocated_momentum", 0.0))
	var note := String(stats.get("engine_momentum_note", ""))
	if engine <= 0.0:
		_fail("Unit 4 has no scaled engine output.")
	if engine + 0.001 < thruster + limb:
		_fail("After 3x engine output, budget is still short: %.2f < %.2f + %.2f" % [engine, thruster, limb])
	if note.contains("engine momentum output") and note.contains("<"):
		_fail("Unit 4 is still reporting engine budget shortage after 3x: %s" % note)
	if note.contains("allocation outside limb range"):
		_fail("Unit 4 should no longer report limb range issue after training dummy repair, got: %s" % note)
	print("UNIT4_AFTER_ENGINE_X3_PROBE ok engine=%.2f required=%.2f note='%s'" % [engine, thruster + limb, note])
	quit()
