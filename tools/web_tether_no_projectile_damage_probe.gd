extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(owner_id: int, name: String, x: float, ranged: bool = false) -> Node:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	var segments: Array = [{
		"node_index": 0,
		"part_kind": "torso",
		"name": "Probe Torso",
		"shape": "polygon",
		"polygon_local": [Vector2(-0.18, -0.12), Vector2(0.18, -0.12), Vector2(0.18, 0.12), Vector2(-0.18, 0.12)],
		"radius": 0.12,
		"damage_type": "blunt",
		"material_class": "metal",
	}]
	if ranged:
		segments = [{
			"node_index": 0,
			"part_kind": "terminal",
			"name": "Probe Web Gun",
			"a_local": Vector2(-0.18, 0.0),
			"b_local": Vector2(0.18, 0.0),
			"radius": 0.04,
			"damage_type": "blunt",
			"material_class": "web_gun",
			"terminal_weapon_kind": "ranged",
			"projectile": true,
			"gun_kind": "web_gun",
			"ammo_kind": "web",
		}]
	fighter.setup_unit({
		"unit_name": name,
		"owner_id": owner_id,
		"role": "hero",
		"stats": {
			"mass": 40.0,
			"health": 100,
			"ammo_capacity": {"web": MainScene.STANDARD_WEB_TETHER_AMMO_CAPACITY},
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": segments,
			"runtime_module_bindings": [],
		},
	})
	fighter.deploy(x, 0.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var attacker = _make_unit(1, "WEB_ATTACKER", 4.0, true)
	var target = _make_unit(2, "WEB_TARGET", 4.55)
	main.all_units = [attacker, target]
	var hp_before := int(target.health)
	var event := {
		"projectile": true,
		"projectile_only": true,
		"gun_activation": true,
		"module_action_profile": "web_tether_activate",
		"muscle_node": 0,
		"collision_group": {"projectile": true, "projectile_only": true, "material_class": "web_gun", "shape": "web_gun", "gun_kind": "web_gun", "ammo_kind": "web"},
		"direction": Vector2.RIGHT,
		"range": MainScene.STANDARD_WEB_TETHER_RANGE_M,
		"lane_range": 0.08,
		"ammo_kind": "web",
		"projectile_style": "web",
		"projectile_behavior": "web_tether",
		"travel_path": "tether",
		"web_target_filter": "all",
		"web_strength": MainScene.STANDARD_WEB_TETHER_STRENGTH,
		"web_break_force": 999.0,
		"web_duration": MainScene.STANDARD_WEB_TETHER_DURATION,
		"web_pull_mode": "mass_duel",
	}
	if not main._fire_runtime_web_tether(attacker, event):
		_fail("Runtime web tether did not fire.")
	if main.active_web_tethers.size() != 1:
		_fail("Runtime web tether did not create a tether state.")
	main._update_web_tethers(0.35)
	if int(target.health) != hp_before:
		_fail("Web tether projectile itself should not deal HP damage.")
	if target.velocity.length() <= 0.001 and attacker.velocity.length() <= 0.001:
		_fail("Web tether did not apply traction velocity.")
	print("WEB_TETHER_NO_PROJECTILE_DAMAGE_PROBE target_hp=%d target_v=%.3f attacker_v=%.3f" % [int(target.health), target.velocity.length(), attacker.velocity.length()])
	quit()
