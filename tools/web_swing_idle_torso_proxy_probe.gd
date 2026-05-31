extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var unit = FighterScene.new()
	root.add_child(unit)
	unit._ready()
	unit.setup_unit({
		"unit_name": "WEB_IDLE_PROXY",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 500,
			"mass": 40.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{
					"node_index": 0,
					"part_kind": "torso",
					"name": "Proxy Torso",
					"polygon_local": [Vector2(-0.2, -0.12), Vector2(0.2, -0.12), Vector2(0.2, 0.12), Vector2(-0.2, 0.12)],
					"radius": 0.12,
				},
				{
					"node_index": 1,
					"part_kind": "terminal",
					"name": "Proxy Web Gun",
					"a_local": Vector2(0.2, 0.0),
					"b_local": Vector2(0.58, 0.0),
					"radius": 0.04,
					"terminal_weapon_kind": "ranged",
					"material_class": "web_gun",
				},
			],
			"runtime_module_bindings": [],
		},
	})
	unit.deploy(4.0, 0.0)
	var saw_terminal := false
	for raw_collider in unit.part_colliders():
		if not (raw_collider is Dictionary):
			continue
		var collider: Dictionary = raw_collider
		if String(collider.get("part_kind", "")) == "terminal":
			saw_terminal = true
			if bool(collider.get("independent_damage", true)):
				_fail("Idle terminal collider should not be independently damaged.")
			if String(collider.get("damage_proxy", "")) != "torso":
				_fail("Idle terminal collider should proxy damage to torso.")
	if not saw_terminal:
		_fail("Probe did not expose a visible idle terminal collider.")
	print("WEB_SWING_IDLE_TORSO_PROXY_PROBE ok")
	quit()
