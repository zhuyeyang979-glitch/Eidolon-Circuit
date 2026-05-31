extends SceneTree

const Renderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var root := Vector2.ZERO
	var tip := Vector2(0.0, 0.72)
	var segment := {
		"node_index": 4,
		"part_kind": "terminal",
		"name": "SHORT CRESCENT SCYTHE",
		"terminal_weapon_kind": "melee",
		"weapon_family": "scythe",
		"shape": "scythe",
		"source_shape": "scythe",
		"damage_type": "tear",
		"visual_mount_side": "right",
		"visual_handedness": "right",
		"orientation_category": "orthogonal_side_mount",
		"orientation_basis": "parent_normal",
		"mount_parent_axis_local": Vector2.RIGHT,
		"a": root,
		"b": tip,
		"radius": 0.08,
	}
	var axis := tip - root
	var node := Renderer.segment_to_component_node(segment)
	var visual_forward := Renderer.terminal_visual_forward(node, axis.normalized())
	if visual_forward.dot(axis.normalized()) < 0.999:
		_fail("Scythe renderer should use resolved segment axis, not stale mount_parent_axis_local.")
		return
	var root_anchor := Renderer.component_connection_anchor((root + tip) * 0.5, node, axis, float(segment.get("radius", 0.08)), root - axis, "root_joint", axis.length(), false)
	if root_anchor.distance_to(root) > 0.0005:
		_fail("Renderer root anchor detached from resolved segment root: %.6f." % root_anchor.distance_to(root))
		return
	print("RUNTIME_SEGMENT_RENDERER_SOCKET_IDENTITY_PROBE ok")
	quit(0)
