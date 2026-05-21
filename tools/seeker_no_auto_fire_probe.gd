extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(name: String, owner_id: int, is_seeker: bool) -> Node:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	var stats := {
		"teamedit_runtime_topology": true,
		"mass": 40.0,
		"health": 120,
		"radius": 0.2,
		"is_homing_launcher": is_seeker,
		"homing_radius": 4.0,
		"homing_interval": 0.01,
		"homing_accuracy": 0.57,
		"homing_damage": 40,
		"homing_damage_type": "bullet",
		"runtime_topology_segments": [{
			"node_index": 0,
			"part_kind": "torso",
			"name": "%s Torso" % name,
			"shape": "polygon",
			"polygon_local": [Vector2(-0.16, -0.1), Vector2(0.16, -0.1), Vector2(0.16, 0.1), Vector2(-0.16, 0.1)],
			"radius": 0.1,
			"damage_type": "blunt",
			"material_class": "metal",
		}],
		"runtime_module_bindings": [],
	}
	fighter.setup_unit({"unit_name": name, "owner_id": owner_id, "role": "hero", "stats": stats})
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var seeker = _make_unit("SEEKER_PROBE", 1, true)
	var target = _make_unit("SEEKER_TARGET", 2, false)
	seeker.deploy(5.0, 0.0)
	target.deploy(5.55, 0.0)
	main.all_units = [seeker, target]
	main.active_units = {
		1: {"hero": seeker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	var target_hp := int(target.health)
	var before_effects: int = main.effects_root.get_child_count() if main.effects_root != null else 0
	main.battle_message = ""
	main.battle_message_timer = 0.0
	for i in range(180):
		main._apply_homing_launchers(1.0 / 60.0)
	var after_effects: int = main.effects_root.get_child_count() if main.effects_root != null else 0
	var message := String(main.battle_message)
	if message.contains("SEEKER"):
		_fail("Automatic seeker warning still appeared: %s" % message)
	if after_effects != before_effects:
		_fail("Automatic seeker spawned VFX: %d -> %d." % [before_effects, after_effects])
	if int(target.health) != target_hp:
		_fail("Automatic seeker changed HP: %d -> %d." % [target_hp, int(target.health)])
	print("SEEKER_NO_AUTO_FIRE_PROBE message='%s' effects=%d hp=%d" % [message, after_effects, int(target.health)])
	quit()
