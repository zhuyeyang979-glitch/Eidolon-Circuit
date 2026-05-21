extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(owner_id: int, name: String, position: Vector2, velocity: Vector2 = Vector2.ZERO) -> Node:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": name,
		"owner_id": owner_id,
		"role": "hero",
		"stats": {
			"health": 1000,
			"mass": 40.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{
					"node_index": 0,
					"part_kind": "torso",
					"name": "%s TORSO" % name,
					"polygon_local": [Vector2(-0.16, -0.12), Vector2(0.16, -0.12), Vector2(0.16, 0.12), Vector2(-0.16, 0.12)],
					"radius": 0.12,
					"stiffness_momentum": MainScene.PART_STIFFNESS_BASE_MOMENTUM,
				},
			],
			"runtime_module_bindings": [],
		},
	})
	fighter.deploy(position.x, position.y)
	fighter.velocity = velocity
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var swinger = _make_unit(1, "WEB_SWINGER", Vector2(4.0, 4.30))
	var target = _make_unit(2, "WEB_TARGET", Vector2(4.0, 4.52))
	var hp_before := int(target.health)
	var event := {
		"projectile": true,
		"projectile_only": true,
		"muscle_node": 0,
		"collision_group": {"projectile": true, "projectile_only": true, "material_class": "web_gun", "shape": "web_gun"},
		"direction": Vector2.DOWN,
		"range": MainScene.STANDARD_WEB_TETHER_RANGE_M,
		"projectile_style": "web",
		"travel_path": "tether",
		"web_strength": MainScene.STANDARD_WEB_TETHER_STRENGTH * 5.0,
		"web_break_force": 999.0,
		"web_duration": MainScene.STANDARD_WEB_TETHER_DURATION,
		"web_anchor_swing": true,
	}
	var anchor: Dictionary = main._web_boundary_anchor_for_event(swinger, event)
	if anchor.is_empty():
		_fail("Boundary anchor unavailable for web swing collision probe.")
	main._start_web_boundary_swing(swinger, event, anchor.get("position", Vector2.ZERO))
	main._update_web_swings(0.35)
	if swinger.velocity.length() <= 0.001:
		_fail("Web swing did not create real velocity.")
	main._separate_unit_part_pair(swinger, target, 1.0 / 60.0)
	if int(target.health) >= hp_before and target.velocity.length() <= 0.001:
		_fail("Web swing collision did not enter runtime contact physics.")
	print("WEB_SWING_MELEE_COLLISION_PROBE target_hp_delta=%d target_v=%.3f" % [hp_before - int(target.health), target.velocity.length()])
	quit()
