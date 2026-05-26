extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = Helpers.setup_main(self)
	var setup := Helpers.build_torso_limb(main)
	if setup.is_empty():
		_fail("Missing torso or limb catalog part.")
		return
	var unit_bp: Dictionary = setup.get("unit_bp", {})
	var limb := int(setup.get("limb", -1))
	var scythe := Helpers.append_loose_scythe_near_limb(main, unit_bp, limb)
	if scythe < 0:
		_fail("Scythe terminal missing.")
		return
	main.editor_topology_node_index = scythe
	main._link_topology_node()
	if int(main.editor_pending_orientation_node_index) != scythe:
		_fail("Manual scythe link did not start side orientation choice.")
		return
	if not Helpers.orientation_buttons_visible(main):
		_fail("Manual scythe link did not show LEFT/RIGHT orientation buttons.")
	if not Helpers.orientation_popup_visible(main):
		_fail("Manual scythe link did not show the side-mount popup.")
		return
	var edge := Helpers.scythe_edge(main, unit_bp, scythe)
	if edge.is_empty():
		_fail("Manual scythe link did not create an edge.")
		return
	var own_socket: String = main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edge, scythe))
	var parent: int = main._topology_edge_other_node(edge, scythe)
	if parent != limb:
		_fail("Manual scythe link should choose nearest legal limb parent, got %d expected %d." % [parent, limb])
		return
	if own_socket != "root_joint":
		_fail("Manual scythe link should use root_joint, got %s." % own_socket)
		return
	print("SCYTHE_MANUAL_LINK_ORIENTATION_POPUP_PROBE ok scythe=%d parent=%d" % [scythe, parent])
	quit(0)
