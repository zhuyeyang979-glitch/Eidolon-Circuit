extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _latest_unit2_path() -> String:
	var dir := DirAccess.open("user://saved_units")
	if dir == null:
		return ""
	var best_path := ""
	var best_time := -1
	for file_name in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var path := "user://saved_units/%s" % file_name
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if not (parsed is Dictionary):
			continue
		if String(Dictionary(parsed).get("unit_name", "")) != "2":
			continue
		var mtime := int(FileAccess.get_modified_time(path))
		if mtime >= best_time:
			best_time = mtime
			best_path = path
	return best_path


func _latest_unit2_blueprint(main) -> Dictionary:
	var path := _latest_unit2_path()
	if path == "":
		_fail("No saved unit named 2 found.")
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Cannot open saved unit 2.")
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON is invalid.")
		return {}
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	return Dictionary(saved.get("blueprint", {})).duplicate(true)


func _first_two_link_binding(stats: Dictionary) -> Dictionary:
	for raw_binding in Array(stats.get("runtime_module_bindings", [])):
		if raw_binding is Dictionary and String(Dictionary(raw_binding).get("module_action_profile", "")) == "two_link_forward_snap":
			return Dictionary(raw_binding)
	return {}


func _active_runtime_colliders(unit) -> Array:
	var result: Array = []
	for raw_collider in unit.part_colliders():
		if not (raw_collider is Dictionary):
			continue
		var collider: Dictionary = raw_collider
		if bool(collider.get("independent_damage", false)) and String(collider.get("part_kind", "")) != "torso":
			result.append(collider)
	return result


func _first_torso_collider(unit) -> Dictionary:
	for raw_collider in unit.part_colliders():
		if raw_collider is Dictionary and String(Dictionary(raw_collider).get("part_kind", "")) == "torso":
			return Dictionary(raw_collider)
	return {}


func _place_target_torso_on_attack(main, target, attack_collider: Dictionary, target_collider: Dictionary) -> float:
	var attack_center: Vector2 = main._collider_center(attack_collider)
	var target_center: Vector2 = main._collider_center(target_collider)
	target.ring_pos += attack_center.x - target_center.x
	target.lane += attack_center.y - target_center.y
	if target.has_method("sync_mobius_from_compat"):
		target.sync_mobius_from_compat(MainScene.RING_LENGTH, true)
	var gap := INF
	for raw_collider in target.part_colliders():
		if raw_collider is Dictionary:
			gap = minf(gap, main._collider_gap(attack_collider, Dictionary(raw_collider)))
	return gap


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit_bp := _latest_unit2_blueprint(main)
	if unit_bp.is_empty():
		return
	var attacker_stats := main._compute_unit_stats(1, "hero", -1, unit_bp.duplicate(true))
	var target_stats := main._compute_unit_stats(2, "hero", -1, unit_bp.duplicate(true))
	var binding := _first_two_link_binding(attacker_stats)
	if binding.is_empty():
		_fail("Saved unit 2 has no runtime Two-Link binding.")
		return
	var attacker = FighterScene.new()
	var target = FighterScene.new()
	root.add_child(attacker)
	root.add_child(target)
	attacker._ready()
	target._ready()
	attacker.setup_unit({"unit_name": "Unit2 Static Attacker", "owner_id": 1, "role": "hero", "stats": attacker_stats})
	target.setup_unit({"unit_name": "Unit2 Static Target", "owner_id": 2, "role": "hero", "stats": target_stats})
	attacker.deploy(5.0, 0.0)
	target.deploy(8.0, 0.0)
	attacker.facing = 1
	target.facing = -1
	var event: Dictionary = attacker.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Saved unit 2 Two-Link action did not start.")
		return
	var action: Dictionary = attacker.runtime_module_actions[0]
	action["timer"] = float(action.get("duration", 0.62)) * 0.74
	attacker.runtime_module_actions[0] = action
	var active_colliders := _active_runtime_colliders(attacker)
	if active_colliders.is_empty():
		_fail("Saved unit 2 Two-Link has no active collider.")
		return
	var attack_collider: Dictionary = active_colliders[active_colliders.size() - 1]
	var target_collider := _first_torso_collider(target)
	if target_collider.is_empty():
		_fail("Target unit 2 has no torso collider.")
		return
	var gap := _place_target_torso_on_attack(main, target, attack_collider, target_collider)
	attacker.velocity = Vector2.ZERO
	target.velocity = Vector2.ZERO
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	if gap > 0.0:
		_fail("Probe setup has no contact; gap=%.4f contact_velocity=%.3f action_speed=%.3f duration=%.3f targets=%s" % [
			gap,
			attacker.contact_velocity_for_collider(attack_collider).length(),
			float(action.get("runtime_contact_speed", 0.0)),
			float(action.get("duration", 0.0)),
			str(action.get("target_nodes", [])),
		])
		return
	var hp_before := int(target.health)
	main._resolve_attack(attacker, event)
	main._separate_unit_part_pair(attacker, target, 1.0 / 60.0)
	var hp_delta := hp_before - int(target.health)
	if hp_delta <= 0:
		var contact_velocity := attacker.contact_velocity_for_collider(attack_collider)
		var active_debug: Array = []
		for raw_active in active_colliders:
			if raw_active is Dictionary:
				var active: Dictionary = raw_active
				active_debug.append({
					"node": int(active.get("node_index", -1)),
					"kind": String(active.get("part_kind", "")),
					"runtime_action": bool(active.get("runtime_action", false)),
					"contact_velocity": attacker.contact_velocity_for_collider(active).length(),
				})
		_fail("Saved unit 2 static Two-Link caused no damage; contact_velocity=%.3f gap=%.4f targets=%s action_speed=%.3f active=%s." % [
			contact_velocity.length(),
			gap,
			str(action.get("target_nodes", [])),
			float(action.get("runtime_contact_speed", 0.0)),
			str(active_debug),
		])
		return
	print("UNIT2_STATIC_TWO_LINK_DAMAGE_PROBE hp_delta=%d max_hp=%d" % [hp_delta, int(target.max_health)])
	quit()
