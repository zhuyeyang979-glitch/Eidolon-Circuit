extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso_with_ports(main, min_ports: int) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part) and main._torso_external_joint_ports(part) >= min_ports:
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso_part := _first_torso_with_ports(main, 3)
	if torso_part < 0:
		_fail("No torso with at least three ports was found.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_part)
	for i in range(3):
		var directions := [Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
		var dir: Vector2 = directions[i]
		main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ROOT %d" % (i + 1), "limb_muscle", 0, dir, [i])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var stats := {"joint_slot_note": "", "swept_collision_note": ""}
	main._apply_joint_slot_motion_limits(stats, "hero", unit_bp)
	if not String(stats.get("swept_collision_note", "")).begins_with("SWEEP OK"):
		_fail("Root-only first limbs should be exempt from sweep collision errors: %s" % String(stats.get("swept_collision_note", "")))
	var root_only_a := {
		"pivot": Vector2(0.42, 0.50),
		"center": 0.0,
		"half": deg_to_rad(150.0),
		"length": 0.65,
		"inner_length": 0.65,
		"radius": 0.035,
	}
	var root_only_b := {
		"pivot": Vector2(0.58, 0.50),
		"center": PI,
		"half": deg_to_rad(150.0),
		"length": 0.65,
		"inner_length": 0.65,
		"radius": 0.035,
	}
	if main._swept_root_limbs_likely_collide(root_only_a, root_only_b):
		_fail("A sweep with only the exempt first segment should not collide.")
	var downstream_a := root_only_a.duplicate(true)
	var downstream_b := root_only_b.duplicate(true)
	downstream_a["inner_length"] = 0.18
	downstream_b["inner_length"] = 0.18
	if not main._swept_root_limbs_likely_collide(downstream_a, downstream_b):
		_fail("Overlapping downstream sweeps should still collide.")
	print("ROOT_LIMB_SWEEP_EXEMPTION_PROBE ok note=%s" % String(stats.get("swept_collision_note", "")))
	quit()
