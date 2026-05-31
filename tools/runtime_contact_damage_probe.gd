extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_attacker():
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Runtime Contact Attacker",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 80.0,
			"normal_damage": 60,
			"runtime_topology_segments": [
				{
					"node_index": 1,
					"part_kind": "terminal",
					"name": "Probe Blade",
					"a_local": Vector2(-0.08, 0.0),
					"b_local": Vector2(0.28, 0.0),
					"radius": 0.08,
					"damage_type": "tear",
					"material_class": "weapon",
					"contact_damage": 80.0,
				},
			],
			"runtime_module_bindings": [],
		},
	})
	fighter.deploy(4.0, 0.0)
	fighter.velocity = Vector2(6.0, 0.0)
	fighter.runtime_module_actions = [{
		"profile": "two_link_forward_snap",
		"target_nodes": [1],
		"attack_key": 1,
		"timer": 0.15,
		"duration": 0.6,
		"state": "normal",
		"startup_ratio": 0.333333,
	}]
	return fighter


func _make_target():
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Runtime Contact Target",
		"owner_id": 2,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 80.0,
			"health": 1000,
			"torso_break_threshold": 1.0,
			"runtime_topology_segments": [
				{
					"node_index": 0,
					"part_kind": "torso",
					"name": "Probe Torso",
					"a_local": Vector2(-0.2, 0.0),
					"b_local": Vector2(0.2, 0.0),
					"shape": "polygon",
					"polygon_local": [Vector2(-0.2, -0.12), Vector2(0.2, -0.12), Vector2(0.2, 0.12), Vector2(-0.2, 0.12)],
					"radius": 0.12,
					"damage_type": "blunt",
					"material_class": "metal",
				},
			],
			"runtime_module_bindings": [],
		},
	})
	fighter.deploy(4.22, 0.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var attacker = _make_attacker()
	var target = _make_target()
	var attacker_collider: Dictionary = attacker.part_colliders()[0]
	var target_collider: Dictionary = target.part_colliders()[0]
	var hp_before := int(target.health)
	main._resolve_passive_contact_hit(attacker, attacker_collider, attacker_collider, target, target_collider, target_collider, Vector2.RIGHT, 0.04, 1.0, false)
	var hp_after := int(target.health)
	if hp_after >= hp_before:
		_fail("Runtime passive contact did not apply damage: before=%d after=%d" % [hp_before, hp_after])
	if target.velocity.x <= 0.0:
		_fail("Runtime passive contact did not transfer momentum.")
	print("RUNTIME_CONTACT_DAMAGE_PROBE hp_delta=%d target_v=%.3f" % [hp_before - hp_after, target.velocity.x])
	quit()
