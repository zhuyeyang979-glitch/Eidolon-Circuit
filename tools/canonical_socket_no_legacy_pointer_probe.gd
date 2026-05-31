extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const TopologyGeometry := preload("res://scripts/topology_geometry.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if TopologyGeometry.canonical_socket_id("side:a") != "root_joint":
		_fail("side:a should import to root_joint.")
	if TopologyGeometry.canonical_socket_id("end:b") != "distal":
		_fail("end:b should import to distal.")
	if TopologyGeometry.canonical_socket_id("torso:3") != "torso_port:3":
		_fail("torso:3 should import to torso_port:3.")
	if main.has_method("_topology_socket_legacy_id"):
		_fail("Main should not expose _topology_socket_legacy_id.")
	if not main.has_method("_topology_canonical_socket_id"):
		_fail("Main should expose _topology_canonical_socket_id.")
	var script := FileAccess.open("res://scripts/topology_geometry.gd", FileAccess.READ)
	if script == null:
		_fail("Cannot read topology_geometry.gd.")
	else:
		var text := script.get_as_text()
		if text.find("socket_legacy_id") >= 0:
			_fail("TopologyGeometry should not expose socket_legacy_id.")
	if failed:
		quit(1)
		return
	print("CANONICAL_SOCKET_NO_LEGACY_POINTER_PROBE ok")
	quit()
