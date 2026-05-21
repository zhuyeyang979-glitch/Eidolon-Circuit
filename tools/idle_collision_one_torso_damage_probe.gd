extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_attacker():
	var unit = FighterScene.new()
	root.add_child(unit)
	unit._ready()
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "Proxy Attacker",
		"stats": {
			"health": 100,
			"mass": 30.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_kind": "torso", "name": "Attacker Torso", "polygon_local": [Vector2(-0.18, -0.1), Vector2(0.18, -0.1), Vector2(0.18, 0.1), Vector2(-0.18, 0.1)], "radius": 0.1},
			],
		},
	})
	unit.deploy(0.0, 0.0)
	unit.velocity = Vector2.RIGHT * 4.0
	return unit


func _make_target():
	var unit = FighterScene.new()
	root.add_child(unit)
	unit._ready()
	unit.setup_unit({
		"owner_id": 2,
		"role": "hero",
		"unit_name": "Proxy Target",
		"stats": {
			"health": 1000,
			"mass": 30.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_kind": "torso", "name": "Target Torso", "polygon_local": [Vector2(-0.18, -0.1), Vector2(0.18, -0.1), Vector2(0.18, 0.1), Vector2(-0.18, 0.1)], "radius": 0.1},
				{"node_index": 1, "part_kind": "limb_muscle", "name": "Target Limb", "a_local": Vector2(-0.18, 0.0), "b_local": Vector2(-0.65, 0.0), "radius": 0.06},
				{"node_index": 2, "part_kind": "terminal", "name": "Target Weapon", "a_local": Vector2(-0.65, 0.0), "b_local": Vector2(-0.9, 0.0), "radius": 0.07, "terminal_weapon_kind": "melee"},
			],
		},
	})
	unit.deploy(0.4, 0.0)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var attacker = _make_attacker()
	var target = _make_target()
	var attacker_collider: Dictionary = attacker.part_colliders()[0]
	var target_colliders := target.part_colliders()
	if target_colliders.size() != 3:
		_fail("Target should expose visual torso, limb, and terminal colliders.")
		return
	var target_limb: Dictionary = target_colliders[1]
	var target_terminal: Dictionary = target_colliders[2]
	if String(target_limb.get("damage_proxy", "")) != "torso" or String(target_terminal.get("damage_proxy", "")) != "torso":
		_fail("Idle limb and terminal must proxy damage to torso.")
		return
	var hp_before := int(target.health)
	main._resolve_runtime_contact_pair_once(attacker, attacker_collider, attacker_collider, target, target_limb, target_limb, Vector2.RIGHT, 0.05)
	var hp_after_first := int(target.health)
	main._resolve_runtime_contact_pair_once(attacker, attacker_collider, attacker_collider, target, target_terminal, target_terminal, Vector2.RIGHT, 0.05)
	var hp_after_second := int(target.health)
	if hp_after_first >= hp_before:
		_fail("First visual idle limb contact should damage target torso through proxy.")
		return
	if hp_after_second != hp_after_first:
		_fail("Second idle part contact in same torso proxy pair should not deal another HP packet.")
		return
	print("IDLE_COLLISION_ONE_TORSO_DAMAGE_PROBE hp_delta=%d" % [hp_before - hp_after_first])
	quit()
