extends RefCounted
class_name TrainingEntryService


func clamped_radius(radius: float, minimum: float, maximum: float, step: float) -> float:
	var safe_step := maxf(0.001, step)
	var clamped := clampf(radius, minimum, maximum)
	var stepped := roundf(clamped / safe_step) * safe_step
	return clampf(stepped, minimum, maximum)


func ball_volume(radius: float) -> float:
	var safe_radius := maxf(0.0, radius)
	return 4.0 / 3.0 * PI * safe_radius * safe_radius * safe_radius


func ball_mass(radius: float, default_radius: float, base_mass: float) -> float:
	var default_volume := ball_volume(default_radius)
	var volume_ratio := ball_volume(radius) / maxf(0.001, default_volume)
	return maxf(1.0, base_mass * volume_ratio)


func ball_stats(radius: float, labels: Dictionary, constants: Dictionary) -> Dictionary:
	var mass := ball_mass(radius, float(constants.get("default_radius", radius)), float(constants.get("base_mass", 12.0)))
	var diameter := radius * 2.0
	return {
		"role": "hero",
		"unit_index": 0,
		"name": String(labels.get("name", "Training Ball Dummy")),
		"unit_name": String(labels.get("unit_name", labels.get("name", "Training Ball Dummy"))),
		"training_ball_dummy": true,
		"health": 1000,
		"max_health": 1000,
		"mass": mass,
		"structural_mass": mass,
		"radius": radius,
		"length": diameter,
		"training_dummy_volume": ball_volume(radius),
		"training_dummy_diameter": diameter,
		"training_dummy_radius_m": radius,
		"teamedit_runtime_topology": false,
		"runtime_topology_segments": [],
		"speed": 0.0,
		"turn_speed": 2.2,
		"turn_command_rate": 2.2,
		"move_momentum": 0.0,
		"brake_power": mass * float(constants.get("brake_delta_v", 0.0)),
		"boost_duration": 0.28,
		"thruster_effective_drive_demand": 0.0,
		"engine_momentum_required": 0.0,
		"ammo_capacity": {"bullet": 0, "chemical": 0, "laser": 0, "explosive": 0, "web": 0},
		"normal_damage": 0,
		"armor_damage": 0,
		"active_damage": 0,
		"damage_type": "blunt",
		"material_class": "training_dummy",
		"contact_damage": 0.0,
		"damage_coeff": 0.0,
		"break_coeff": 0.0,
		"stiffness": mass * 18.0,
		"stiffness_momentum": mass * 18.0,
		"path_stiffness_momentum": mass * 18.0,
		"deploy_cost": 0,
		"cost": 0,
		"deploy_wait": 0.0,
		"primary_color": Color(0.32, 0.86, 1.0, 1.0),
		"accent_color": Color(1.0, 0.86, 0.28, 1.0),
	}


func ball_entry(radius: float, labels: Dictionary) -> Dictionary:
	var unit_name := String(labels.get("unit_name", labels.get("name", "Training Ball Dummy")))
	return {
		"role": "hero",
		"blueprint": {
			"name": String(labels.get("name", unit_name)),
			"unit_name": unit_name,
			"role": "hero",
			"training_ball_dummy": true,
			"training_dummy_radius_m": radius,
		},
	}


func ball_intro_segments(radius: float) -> Array:
	return [{
		"part_kind": "torso",
		"name": "TRAINING BALL",
		"a_local": Vector2.ZERO,
		"b_local": Vector2.ZERO,
		"radius": radius,
		"material_class": "training_dummy",
	}]


func pending_imports(import_units: Array, import_role_key: String, import_blueprint: Dictionary) -> Array:
	var imports := import_units.duplicate(true)
	if imports.is_empty() and not import_blueprint.is_empty() and import_role_key != "":
		imports.append({
			"role": import_role_key,
			"blueprint": import_blueprint.duplicate(true),
		})
	return imports


func loadout_from_imports(imports: Array, role_order: Array, legality_fn: Callable, apply_pose_fn: Callable) -> Dictionary:
	if imports.is_empty():
		return {"ok": false, "has_imports": false, "error": "", "clear_import": false}
	var next_roster := _blank_roster(role_order)
	var next_loadout: Array = []
	var first_hero_slot := -1
	for raw_import in imports:
		if not (raw_import is Dictionary):
			continue
		var import_entry: Dictionary = raw_import
		var role_key := String(import_entry.get("role", "hero"))
		if not role_order.has(role_key) or not (import_entry.get("blueprint", {}) is Dictionary):
			continue
		var unit_bp: Dictionary = Dictionary(import_entry.get("blueprint", {})).duplicate(true)
		var illegal_note := ""
		if legality_fn.is_valid():
			illegal_note = String(legality_fn.call(role_key, unit_bp))
		if illegal_note != "":
			return {
				"ok": false,
				"has_imports": true,
				"error": illegal_note,
				"clear_import": true,
			}
		unit_bp["role"] = role_key
		var save_kind := String(import_entry.get("save_kind", unit_bp.get("save_kind", "single_unit")))
		if save_kind == "":
			save_kind = "single_unit"
		unit_bp["save_kind"] = save_kind
		if save_kind == "puppet_group":
			unit_bp["puppet_group_blueprints"] = Array(import_entry.get("puppet_group_blueprints", unit_bp.get("puppet_group_blueprints", []))).duplicate(true)
			unit_bp["group_count"] = Array(unit_bp.get("puppet_group_blueprints", [])).size()
		if apply_pose_fn.is_valid():
			apply_pose_fn.call(unit_bp)
		var roster: Array = Array(next_roster.get(role_key, []))
		var unit_index := roster.size()
		roster.append(unit_bp)
		next_roster[role_key] = roster
		next_loadout.append({"role": role_key, "index": unit_index})
		if role_key == "hero" and first_hero_slot < 0:
			first_hero_slot = next_loadout.size() - 1
	if next_loadout.is_empty():
		return {"ok": false, "has_imports": true, "error": "", "clear_import": false}
	var initial_slot := first_hero_slot if first_hero_slot >= 0 else 0
	return {
		"ok": true,
		"has_imports": true,
		"roster": next_roster,
		"loadout": next_loadout,
		"initial_slot": initial_slot,
		"initial_role": String(Dictionary(next_loadout[initial_slot]).get("role", "hero")),
		"clear_import": true,
	}


func first_legal_hero_entry(roster: Dictionary, active_indices: Dictionary, legality_fn: Callable) -> Dictionary:
	var hero_roster: Array = Array(roster.get("hero", []))
	if hero_roster.is_empty():
		return {}
	var active_index := clampi(int(active_indices.get("hero", 0)), 0, hero_roster.size() - 1)
	var ordered_indices: Array = [active_index]
	for i in range(hero_roster.size()):
		if not ordered_indices.has(i):
			ordered_indices.append(i)
	for raw_index in ordered_indices:
		var unit_index := int(raw_index)
		var entry := {"role": "hero", "index": unit_index}
		if not legality_fn.is_valid() or bool(legality_fn.call(entry)):
			return entry
	return {}


func starter_loadout(starter_blueprint: Dictionary) -> Dictionary:
	if starter_blueprint.is_empty():
		return {"ok": false}
	var roster := _blank_roster(["hero", "puppet", "barrier"])
	roster["hero"] = [starter_blueprint.duplicate(true)]
	return {
		"ok": true,
		"roster": roster,
		"loadout": [{"role": "hero", "index": 0}],
		"initial_slot": 0,
		"initial_role": "hero",
	}


func training_side_assignment(player_state: Dictionary, dummy_entry: Dictionary, seat: int) -> Dictionary:
	var player_roster: Dictionary = Dictionary(player_state.get("roster", {})).duplicate(true)
	var player_loadout: Array = Array(player_state.get("loadout", [])).duplicate(true)
	if player_roster.is_empty() or player_loadout.is_empty():
		return {
			"ok": false,
			"error": "INVALID: no training player unit has been prepared.",
		}
	if dummy_entry.is_empty() or not (dummy_entry.get("blueprint", {}) is Dictionary):
		return {"ok": false, "error": ""}
	var dummy_roster := _roster_from_single(dummy_entry)
	var dummy_loadout := [{"role": String(dummy_entry.get("role", "hero")), "index": 0}]
	var player_seat := clampi(seat, 1, 3)
	var blueprints := {}
	var sortie_loadouts := {}
	var initial_slots := {}
	var initial_roles := {}
	if player_seat == 2:
		blueprints[1] = dummy_roster
		sortie_loadouts[1] = dummy_loadout
		initial_slots[1] = 0
		initial_roles[1] = String(dummy_loadout[0].get("role", "hero"))
		blueprints[2] = player_roster
		sortie_loadouts[2] = player_loadout
		initial_slots[2] = int(player_state.get("initial_slot", 0))
		initial_roles[2] = String(player_state.get("initial_role", "hero"))
	else:
		blueprints[1] = player_roster
		sortie_loadouts[1] = player_loadout
		initial_slots[1] = int(player_state.get("initial_slot", 0))
		initial_roles[1] = String(player_state.get("initial_role", "hero"))
		blueprints[2] = dummy_roster
		sortie_loadouts[2] = dummy_loadout
		initial_slots[2] = 0
		initial_roles[2] = String(dummy_loadout[0].get("role", "hero"))
	return {
		"ok": true,
		"player_seat": player_seat,
		"blueprints": blueprints,
		"sortie_loadouts": sortie_loadouts,
		"initial_sortie_slot": initial_slots,
		"initial_role": initial_roles,
		"active_roster_indices": {
			1: {"hero": 0, "puppet": 0, "barrier": 0},
			2: {"hero": 0, "puppet": 0, "barrier": 0},
		},
	}


func _blank_roster(role_order: Array) -> Dictionary:
	var roster := {}
	for raw_role in role_order:
		roster[String(raw_role)] = []
	return roster


func _roster_from_single(entry: Dictionary) -> Dictionary:
	var roster := _blank_roster(["hero", "puppet", "barrier"])
	if entry.is_empty() or not (entry.get("blueprint", {}) is Dictionary):
		return roster
	var role_key := String(entry.get("role", "hero"))
	if not roster.has(role_key):
		return roster
	var bp: Dictionary = Dictionary(entry.get("blueprint", {})).duplicate(true)
	bp["role"] = role_key
	roster[role_key] = [bp]
	return roster
