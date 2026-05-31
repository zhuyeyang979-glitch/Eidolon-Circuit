extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var action_model := FileAccess.get_file_as_string("res://scripts/services/fighter_action_model.gd")
	if action_model.is_empty():
		_fail("Unable to read FighterActionModel.")
		return
	for forbidden in [
		"TopologyPoseResolver",
		"resolve_runtime_segments",
		"runtime_topology_segments",
		"runtime_topology_edges",
		"a_local",
		"b_local",
		"axis_local",
		"socket",
		"collider",
		"polygon",
		"capsule",
		"segment",
		"root_anchor",
		"tip_anchor",
		"_runtime_segment",
		"_runtime_local",
		"Vector2",
	]:
		if action_model.contains(forbidden):
			_fail("FighterActionModel must remain scalar-only; found geometry token: %s" % forbidden)
			return
	for required_model_token in [
		"func runtime_action_curve_intent",
		"func runtime_action_variant_pose_intent",
		"\"startup_t\"",
		"\"recovery_t\"",
		"\"recovery_cos_t\"",
		"\"pose_t\"",
		"\"target_t\"",
		"\"feint_ghost_visible\"",
		"\"feint_retarget_allowed\"",
	]:
		if not action_model.contains(required_model_token):
			_fail("FighterActionModel missing scalar boundary token: %s" % required_model_token)
			return
	var fighter := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	if fighter.is_empty():
		_fail("Unable to read fighter.gd.")
		return
	for required_fighter_token in [
		"_action_model().runtime_action_curve_intent(action, TWO_LINK_DEFAULT_STARTUP_RATIO)",
		"_action_model().runtime_action_variant_pose_intent(action, TWO_LINK_DEFAULT_STARTUP_RATIO)",
		"TopologyPoseResolver.resolve_runtime_segments(result, Array(stats.get(\"runtime_topology_edges\", [])), pose_overrides, false)",
		"pose_overrides[key] = Dictionary(overrides[key]).duplicate(true)",
		"override[\"a_local\"]",
		"override[\"b_local\"]",
		"override[\"axis_local\"]",
		"_runtime_side_mount_action_angle_offset(binding) + delta",
	]:
		if not fighter.contains(required_fighter_token):
			_fail("Fighter missing runtime action geometry ownership token: %s" % required_fighter_token)
			return
	var action_model_slice := _function_body(fighter, "func _runtime_action_curve_intent")
	if action_model_slice.is_empty() or action_model_slice.contains("a_local") or action_model_slice.contains("b_local") or action_model_slice.contains("TopologyPoseResolver"):
		_fail("Fighter action-model wrappers must stay scalar-only.")
		return
	print("RUNTIME_ACTION_GEOMETRY_BOUNDARY_PROBE ok")
	quit(0)


func _function_body(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		return source.substr(start)
	return source.substr(start, next - start)
