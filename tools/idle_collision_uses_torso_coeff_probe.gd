extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit():
	var unit = FighterScene.new()
	root.add_child(unit)
	unit._ready()
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "IdleTorsoColliderProbe",
		"stats": {
			"health": 100,
			"mass": 20.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{
					"node_index": 0,
					"part_kind": "torso",
					"name": "Torso",
					"polygon_local": [Vector2(-0.2, -0.1), Vector2(0.2, -0.1), Vector2(0.2, 0.1), Vector2(-0.2, 0.1)],
					"radius": 0.1,
				},
				{
					"node_index": 1,
					"part_kind": "limb_muscle",
					"name": "Idle Limb",
					"a_local": Vector2(0.2, 0.0),
					"b_local": Vector2(0.7, 0.0),
					"radius": 0.04,
				},
				{
					"node_index": 2,
					"part_kind": "terminal",
					"name": "Idle Weapon",
					"a_local": Vector2(0.7, 0.0),
					"b_local": Vector2(0.95, 0.0),
					"radius": 0.05,
				},
			],
			"runtime_module_bindings": [],
		},
	})
	unit.deploy(0.0, 0.0)
	return unit


func _init() -> void:
	var unit = _make_unit()
	var colliders: Array = unit.part_colliders()
	if colliders.size() != 3:
		_fail("Idle/recovery unit should expose all visible colliders, got %d" % colliders.size())
		return
	var torso_count := 0
	var proxied_count := 0
	for raw in colliders:
		var collider: Dictionary = raw
		if String(collider.get("part_kind", "")) == "torso":
			torso_count += 1
			if bool(collider.get("independent_damage", false)) != true:
				_fail("Torso should keep independent damage in idle state.")
				return
		else:
			if String(collider.get("damage_proxy", "")) != "torso" or bool(collider.get("independent_damage", true)):
				_fail("Idle non-torso collider should proxy damage to torso: %s" % str(collider))
				return
			proxied_count += 1
	if torso_count != 1 or proxied_count != 2:
		_fail("Expected one torso and two torso-proxied colliders.")
		return
	print("IDLE_COLLISION_USES_TORSO_COEFF_PROBE ok")
	quit()
