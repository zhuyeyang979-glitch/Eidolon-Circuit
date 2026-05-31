extends SceneTree

const AssemblyBoardRenderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var torso_node := {
		"is_torso": true,
		"part_kind": "torso",
		"joint_ports": 4,
		"component_length": 2.0,
	}
	var metrics := AssemblyBoardRenderer.component_display_metrics(torso_node, 1.0, 2.0, false)
	var length := float(metrics.get("length", 0.0))
	var front := float(metrics.get("front_width", 0.0))
	var rear := float(metrics.get("rear_width", 0.0))
	if length <= 0.0:
		_fail("Torso display metrics returned invalid length.")
	if absf(front / length - 0.36) > 0.015:
		_fail("Torso front width ratio should be near 0.36, got %.3f." % (front / length))
	if absf(rear / length - 0.72) > 0.015:
		_fail("Torso rear width ratio should be near 0.72, got %.3f." % (rear / length))
	var ports := AssemblyBoardRenderer.torso_port_positions(Vector2.ZERO, torso_node, Vector2.RIGHT, 1.0, 2.0, false)
	if ports.size() != 4:
		_fail("Torso profile should expose 4 display ports, got %d." % ports.size())
	print("TORSO_DISPLAY_AREA_PROFILE_PROBE ok front=%.3f rear=%.3f ports=%d" % [front / length, rear / length, ports.size()])
	quit()
