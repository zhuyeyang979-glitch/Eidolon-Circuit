extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _runtime_stats(main, owner_id: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	var nodes: Array = []
	var edges: Array = []
	main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), _first_torso_index(main))
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var stats: Dictionary = main._compute_unit_stats(owner_id, "hero", -1, unit_bp)
	stats["teamedit_runtime_topology"] = true
	stats["mass"] = 24.0
	return stats


func _make_fighter(main, owner_id: int, x: float, y: float):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "RuntimeProbe%d" % owner_id, "owner_id": owner_id, "role": "hero", "stats": _runtime_stats(main, owner_id)})
	fighter.deploy(x, y)
	fighter.velocity = Vector2.ZERO
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var a = _make_fighter(main, 1, 4.0, 0.0)
	var b = _make_fighter(main, 2, 4.0, 0.0)
	var before_distance := absf(main._ring_delta(a.ring_pos, b.ring_pos))
	main._separate_unit_part_pair(a, b, 1.0 / 60.0)
	var after_distance := absf(main._ring_delta(a.ring_pos, b.ring_pos))
	if a.velocity.length() > 0.0001 or b.velocity.length() > 0.0001:
		_fail("Runtime penetration correction injected velocity: a=%s b=%s" % [str(a.velocity), str(b.velocity)])
	if after_distance <= before_distance:
		_fail("Runtime penetration correction did not separate positions.")
	print("RUNTIME_PENETRATION_NO_VELOCITY_KICK_PROBE before=%.4f after=%.4f" % [before_distance, after_distance])
	quit()
