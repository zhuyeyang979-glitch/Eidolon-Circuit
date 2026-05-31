extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var file := FileAccess.open("res://scripts/fighter.gd", FileAccess.READ)
	if file == null:
		_fail("Could not read fighter.gd.")
		return
	var text := file.get_as_text()
	if not text.contains("TopologyPoseResolver.resolve_runtime_segments(result, Array(stats.get(\"runtime_topology_edges\", [])), pose_overrides, false)"):
		_fail("Fighter runtime topology world path must pass dynamic overrides through TopologyPoseResolver.")
		return
	if not text.contains("pose_overrides[key] = Dictionary(overrides[key]).duplicate(true)"):
		_fail("Runtime module overrides must be pose_overrides, not final unconstrained segment replacements.")
		return
	print("MODULE_OVERRIDE_USES_POSE_RESOLVER_PROBE ok")
	quit(0)
