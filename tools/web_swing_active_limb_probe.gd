extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit = FighterScene.new()
	root.add_child(unit)
	unit._ready()
	unit.setup_unit({
		"unit_name": "WEB_ACTIVE_LIMB",
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
					"name": "Active Torso",
					"polygon_local": [Vector2(-0.2, -0.12), Vector2(0.2, -0.12), Vector2(0.2, 0.12), Vector2(-0.2, 0.12)],
					"radius": 0.12,
				},
				{
					"node_index": 2,
					"part_kind": "terminal",
					"name": "Active Gauntlet",
					"a_local": Vector2(0.2, 0.0),
					"b_local": Vector2(0.62, 0.0),
					"radius": 0.05,
					"terminal_weapon_kind": "melee",
					"material_class": "weapon",
				},
			],
			"runtime_module_bindings": [],
		},
	})
	unit.deploy(4.0, 4.2)
	unit.runtime_module_actions = [{
		"profile": "two_link_forward_snap",
		"target_nodes": [2],
		"timer": 0.10,
		"duration": 1.0,
		"state": "normal",
	}]
	var active_terminal := false
	for raw_collider in unit.part_colliders():
		if not (raw_collider is Dictionary):
			continue
		var collider: Dictionary = raw_collider
		if int(collider.get("node_index", -1)) == 2:
			active_terminal = bool(collider.get("independent_damage", false))
	if not active_terminal:
		_fail("Active module terminal should be independently damageable.")
	var event := {
		"projectile": true,
		"projectile_only": true,
		"muscle_node": 2,
		"collision_group": {"projectile": true, "projectile_only": true, "material_class": "web_gun", "shape": "web_gun"},
		"direction": Vector2.DOWN,
		"range": MainScene.STANDARD_WEB_TETHER_RANGE_M,
		"projectile_style": "web",
		"travel_path": "tether",
		"web_strength": MainScene.STANDARD_WEB_TETHER_STRENGTH,
		"web_break_force": 999.0,
		"web_duration": MainScene.STANDARD_WEB_TETHER_DURATION,
		"web_anchor_swing": true,
	}
	var anchor: Dictionary = main._web_boundary_anchor_for_event(unit, event)
	if anchor.is_empty():
		_fail("Boundary anchor unavailable for active limb swing probe.")
	main._start_web_boundary_swing(unit, event, anchor.get("position", Vector2.ZERO))
	main._update_web_swings(0.35)
	if unit.velocity.length() <= 0.001:
		_fail("Web swing did not affect active limb unit velocity.")
	if unit.runtime_module_actions.is_empty():
		_fail("Web swing should not cancel an unrelated active melee module.")
	print("WEB_SWING_ACTIVE_LIMB_PROBE velocity=%.3f" % unit.velocity.length())
	quit()
