extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var bp := main._make_editor_blank_blueprint("hero")
	bp["custom_topology"] = main._default_free_canvas_topology("hero")
	var topology: Dictionary = bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	if nodes.size() < 2:
		_fail("Default topology did not provide enough nodes for entry-pose test.")
	var node: Dictionary = Dictionary(nodes[1]).duplicate(true)
	node["axis"] = Vector2.UP
	node["rotation"] = Vector2.UP.angle()
	nodes[1] = node
	topology["nodes"] = nodes
	bp["custom_topology"] = topology
	bp["entry_pose"] = main._entry_pose_from_topology(bp)
	var restored := bp.duplicate(true)
	var restored_topology: Dictionary = restored.get("custom_topology", {})
	var restored_nodes: Array = restored_topology.get("nodes", [])
	var reset_node: Dictionary = Dictionary(restored_nodes[1]).duplicate(true)
	reset_node["axis"] = Vector2.RIGHT
	reset_node["rotation"] = 0.0
	restored_nodes[1] = reset_node
	restored_topology["nodes"] = restored_nodes
	restored["custom_topology"] = restored_topology
	main._apply_entry_pose_to_blueprint(restored)
	var applied_nodes: Array = Dictionary(restored.get("custom_topology", {})).get("nodes", [])
	var applied_axis: Vector2 = main._topology_node_axis(applied_nodes[1])
	if applied_axis.distance_to(Vector2.UP) > 0.01:
		_fail("Entry pose did not restore the saved local axis.")
	print("ENTRY_POSE_FK_PROBE ok axis=%s" % str(applied_axis))
	quit()
