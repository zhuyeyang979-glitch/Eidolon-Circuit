extends RefCounted
class_name BattleActorCommandService


func deploy_tick_plan(pending_roles: Array, delta: float) -> Array:
	var plans: Array = []
	for raw_entry in pending_roles:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var timer := float(entry.get("timer", 0.0))
		if timer <= 0.0:
			continue
		var next_timer := timer - delta
		plans.append({
			"player_id": int(entry.get("player_id", 0)),
			"role_key": String(entry.get("role_key", "")),
			"timer_before": timer,
			"timer_after": maxf(0.0, next_timer),
			"update_preview": true,
			"finish": next_timer <= 0.0,
		})
	return plans


func summon_gate_intent(context: Dictionary) -> Dictionary:
	var role_key := String(context.get("role_key", "hero"))
	if role_key == "puppet" and bool(context.get("puppet_group_live", false)):
		return {"accepted": false, "reason": "puppet_online", "illegal_feedback": true}
	if role_key != "puppet" and bool(context.get("existing_live", false)):
		return {"accepted": false, "reason": "already_online", "illegal_feedback": true}
	if bool(context.get("pending", false)):
		return {"accepted": false, "reason": "already_pending", "illegal_feedback": true}
	if bool(context.get("barrier_blocked", false)):
		return {"accepted": false, "reason": "barrier_blocked", "illegal_feedback": true}
	if not bool(context.get("free", false)) and float(context.get("resource", 0.0)) < float(context.get("deploy_cost", 0.0)):
		return {"accepted": false, "reason": "resource_short", "message": true, "illegal_sfx": bool(context.get("alarm", true))}
	return {"accepted": true, "reason": "accepted"}


func auto_summon_intent(context: Dictionary) -> Dictionary:
	if context.has("candidates"):
		for raw_candidate in Array(context.get("candidates", [])):
			if not (raw_candidate is Dictionary):
				continue
			var candidate: Dictionary = raw_candidate
			if not bool(candidate.get("valid", false)):
				continue
			if not bool(candidate.get("role_allowed", false)):
				continue
			if not bool(candidate.get("available", false)):
				continue
			if not bool(candidate.get("affordable", false)):
				continue
			return {
				"found": true,
				"role_key": String(candidate.get("role", "hero")),
				"unit_index": int(candidate.get("index", 0)),
				"candidate": candidate.duplicate(true),
			}
		return {"found": false}

	var auto_timer := maxf(0.0, float(context.get("auto_timer", 0.0)) - float(context.get("delta", 0.0)))
	var idle_timer := maxf(0.0, float(context.get("idle_timer", 0.0)) - float(context.get("delta", 0.0)))
	var intents: Array = []
	if not bool(context.get("has_live_mech", false)) and not bool(context.get("has_pending_mech", false)) and auto_timer <= 0.0:
		intents.append({"reason": "no_mech", "role_filter": ["hero", "puppet"], "reset_timer": "auto"})
	if bool(context.get("hero_live", false)) and bool(context.get("hero_has_soul", false)) and idle_timer <= 0.0:
		var idle_age := float(context.get("now", 0.0)) - float(context.get("last_attack_time", context.get("now", 0.0)))
		if idle_age >= float(context.get("idle_seconds", 10.0)):
			intents.append({"reason": "soul_idle", "role_filter": ["puppet"], "reset_timer": "idle", "touch_last_attack_on_success": true})
	return {
		"auto_timer": auto_timer,
		"idle_timer": idle_timer,
		"intents": intents,
	}


func auto_summon_role_available(role_key: String, context: Dictionary) -> bool:
	if not bool(context.get("role_known", false)):
		return false
	if not bool(context.get("player_known", false)):
		return false
	if bool(context.get("pending", false)):
		return false
	if role_key == "puppet":
		return int(context.get("live_primary_puppet_count", 0)) <= 0
	return not bool(context.get("existing_live", false))


func auto_summon_mech_presence(context: Dictionary) -> Dictionary:
	return {
		"has_live_mech": bool(context.get("hero_live", false)) or int(context.get("live_primary_puppet_count", 0)) > 0,
		"has_pending_mech": bool(context.get("hero_pending", false)) or bool(context.get("puppet_pending", false)),
	}


func ai_battle_original_player_is_ai(ai_battle_seat: int, player_id: int) -> bool:
	if ai_battle_seat == 3:
		return true
	return player_id == 2


func ai_battle_roster_prepare_intent(context: Dictionary) -> Dictionary:
	var ai_controlled := bool(context.get("ai_controlled", false))
	var roster_empty := bool(context.get("roster_empty", false))
	var manual_locked := bool(context.get("manual_locked", false))
	var auto_generate := (ai_controlled and not manual_locked) or (roster_empty and not manual_locked)
	return {
		"auto_generate": auto_generate,
		"legalize": ai_controlled or auto_generate,
		"force_generate": auto_generate or roster_empty,
		"template_choice": "random" if auto_generate else "",
	}


func ai_battle_entry_repair_intent(context: Dictionary) -> Dictionary:
	if bool(context.get("summary_valid", false)):
		return {"repair": false, "force_generate": false, "template_choice": String(context.get("template_choice", ""))}
	if not bool(context.get("mode_is_ai", false)) or not bool(context.get("ai_controlled", false)):
		return {"repair": false, "force_generate": false, "template_choice": String(context.get("template_choice", ""))}
	var template_choice := String(context.get("template_choice", "teamedit_generated"))
	if not bool(context.get("manual_locked", false)):
		template_choice = "random"
	return {
		"repair": true,
		"force_generate": true,
		"template_choice": template_choice,
	}


func matchup_sortie_selection_intent(context: Dictionary) -> Dictionary:
	if bool(context.get("ai_controlled", false)):
		return {
			"action": "ai_loadout",
			"build_ai_loadout": true,
			"normalize_initial": true,
			"clear_loadout": false,
			"ensure_bindings": true,
		}
	return {
		"action": "clear",
		"build_ai_loadout": false,
		"normalize_initial": false,
		"clear_loadout": true,
		"initial_slot": 0,
		"ensure_bindings": true,
	}


func ai_battle_seat_selection_intent(context: Dictionary) -> Dictionary:
	var seat := clampi(int(context.get("requested_seat", 1)), 1, 3)
	var mode_is_training := bool(context.get("mode_is_training", false))
	var set_scout := false
	var scout_player := 0
	if not mode_is_training:
		if seat == 3 and not bool(context.get("p1_manual_locked", false)):
			set_scout = true
			scout_player = 1
		elif seat == 2:
			set_scout = true
			scout_player = 1
	return {
		"seat": seat,
		"training_seat_confirmed": mode_is_training,
		"configure_training_sides": mode_is_training,
		"set_scout_sortie_player": set_scout,
		"scout_sortie_player_id": scout_player,
		"update_scout_ui": true,
	}


func scout_sortie_side_selection_intent(player_id: int, roster_order: Array) -> Dictionary:
	var clamped_player_id := clampi(player_id, 1, 2)
	var intent := {
		"scout_sortie_player_id": clamped_player_id,
		"scout_selected_player_id": clamped_player_id,
		"set_selected_entry": false,
		"selected_entry": {},
		"update_scout_ui": true,
	}
	if not roster_order.is_empty() and roster_order[0] is Dictionary:
		intent["set_selected_entry"] = true
		intent["selected_entry"] = Dictionary(roster_order[0]).duplicate(true)
	return intent


func scout_ai_team_button_intent(player_id: int, mode: String, lock_after: bool, current_template_key: String, template_order: Array) -> Dictionary:
	var clamped_player_id := clampi(player_id, 1, 2)
	if mode == "edit":
		return {
			"player_id": clamped_player_id,
			"action": "edit",
			"show_editor": true,
			"generate_team": false,
			"set_template_choice": false,
			"template_key": "",
			"lock_after": lock_after,
		}
	if mode == "cycle":
		if template_order.is_empty():
			return {
				"player_id": clamped_player_id,
				"action": "none",
				"show_editor": false,
				"generate_team": false,
				"set_template_choice": false,
				"template_key": "",
				"lock_after": true,
			}
		var index := template_order.find(current_template_key)
		if index < 0:
			index = 0
		var next_key := String(template_order[_wrapped_index(index + 1, template_order.size())])
		return {
			"player_id": clamped_player_id,
			"action": "generate",
			"show_editor": false,
			"generate_team": true,
			"set_template_choice": false,
			"template_key": next_key,
			"lock_after": true,
		}
	return {
		"player_id": clamped_player_id,
		"action": "generate",
		"show_editor": false,
		"generate_team": true,
		"set_template_choice": true,
		"template_choice": "random",
		"template_key": "random",
		"lock_after": lock_after,
	}


func team_color_index(player_id: int, color_indices: Dictionary, preset_count: int) -> int:
	var fallback := 0 if player_id == 1 else 1
	var raw := int(color_indices.get(player_id, fallback))
	if raw < 0:
		return -1
	if preset_count <= 0:
		return -1
	return clampi(raw, 0, preset_count - 1)


func team_color_preset(player_id: int, color_indices: Dictionary, custom_colors: Dictionary, presets: Array) -> Dictionary:
	var color_index := team_color_index(player_id, color_indices, presets.size())
	if color_index >= 0 and color_index < presets.size() and presets[color_index] is Dictionary:
		return Dictionary(presets[color_index]).duplicate(true)
	var custom: Variant = custom_colors.get(player_id, custom_colors.get(1, {}))
	return Dictionary(custom).duplicate(true) if custom is Dictionary else {}


func team_color_select_intent(player_id: int, color_index: int, preset_count: int, manual_lock_on_select: bool) -> Dictionary:
	var clamped_player_id := clampi(player_id, 1, 2)
	var clamped_color_index := -1
	if preset_count > 0:
		clamped_color_index = clampi(color_index, 0, preset_count - 1)
	return {
		"player_id": clamped_player_id,
		"color_index": clamped_color_index,
		"set_manual_lock": manual_lock_on_select,
		"manual_locked": true,
		"update_ui": true,
	}


func team_color_name(preset: Dictionary, ui_is_zh: bool) -> String:
	if ui_is_zh:
		return String(preset.get("name", preset.get("name_en", "自定义")))
	return String(preset.get("name_en", preset.get("name", "CUSTOM")))


func valid_roster_entry(entry: Dictionary, roster_sizes: Dictionary, role_order: Array) -> bool:
	var role_key := String(entry.get("role", ""))
	if not role_order.has(role_key):
		return false
	var unit_index := int(entry.get("index", -1))
	return unit_index >= 0 and unit_index < int(roster_sizes.get(role_key, 0))


func sortie_loadout_plan(raw_loadout: Array, roster_sizes: Dictionary, role_order: Array, sortie_cap: int, initial_slot: int) -> Dictionary:
	var cap := maxi(0, sortie_cap)
	if cap <= 0:
		return {"loadout": [], "initial_slot": 0}
	var fixed: Array = []
	var seen := {}
	for item in raw_loadout:
		if not (item is Dictionary):
			continue
		var entry: Dictionary = Dictionary(item).duplicate(true)
		var role_key := String(entry.get("role", ""))
		var unit_index := int(entry.get("index", -1))
		if not valid_roster_entry(entry, roster_sizes, role_order):
			continue
		var ref := _entry_ref_from_values(role_key, unit_index)
		if seen.has(ref):
			continue
		seen[ref] = true
		fixed.append(entry)
		if fixed.size() >= cap:
			break
	var next_initial_slot := 0 if fixed.is_empty() else clampi(initial_slot, 0, fixed.size() - 1)
	return {"loadout": fixed, "initial_slot": next_initial_slot}


func sortie_after_delete_plan(raw_loadout: Array, roster_sizes: Dictionary, role_order: Array, sortie_cap: int, initial_slot: int, deleted_role: String, deleted_index: int) -> Dictionary:
	var cap := maxi(0, sortie_cap)
	if cap <= 0:
		return {"loadout": [], "initial_slot": 0}
	var fixed: Array = []
	var seen := {}
	for item in raw_loadout:
		if not (item is Dictionary):
			continue
		var entry: Dictionary = Dictionary(item).duplicate(true)
		if String(entry.get("role", "")) == deleted_role:
			var unit_index := int(entry.get("index", -1))
			if unit_index == deleted_index:
				continue
			if unit_index > deleted_index:
				entry["index"] = unit_index - 1
		if not valid_roster_entry(entry, roster_sizes, role_order):
			continue
		var role_key := String(entry.get("role", ""))
		var next_index := int(entry.get("index", -1))
		var ref := _entry_ref_from_values(role_key, next_index)
		if seen.has(ref):
			continue
		seen[ref] = true
		fixed.append(entry)
		if fixed.size() >= cap:
			break
	var next_initial_slot := 0 if fixed.is_empty() else clampi(initial_slot, 0, fixed.size() - 1)
	return {"loadout": fixed, "initial_slot": next_initial_slot}


func sortie_initial_cost_plan(loadout: Array, initial_slot: int, starter_cost_valid: Array) -> Dictionary:
	if loadout.is_empty():
		return {"found": false, "initial_slot": 0}
	var current_slot := clampi(initial_slot, 0, loadout.size() - 1)
	if current_slot < starter_cost_valid.size() and bool(starter_cost_valid[current_slot]):
		return {"found": true, "initial_slot": current_slot}
	for i in range(loadout.size()):
		if i < starter_cost_valid.size() and bool(starter_cost_valid[i]):
			return {"found": true, "initial_slot": i}
	return {"found": false, "initial_slot": current_slot}


func sortie_toggle_plan(loadout: Array, entry: Dictionary, existing_position: int, sortie_cap: int, initial_slot: int) -> Dictionary:
	var next_loadout := loadout.duplicate(true)
	if existing_position >= 0:
		if existing_position >= next_loadout.size():
			return {"action": "none", "loadout": next_loadout, "initial_slot": initial_slot}
		next_loadout.remove_at(existing_position)
		var next_initial_slot := 0 if next_loadout.is_empty() else clampi(initial_slot, 0, next_loadout.size() - 1)
		return {"action": "remove", "loadout": next_loadout, "initial_slot": next_initial_slot}
	if next_loadout.size() >= maxi(0, sortie_cap):
		return {"action": "full", "loadout": next_loadout, "initial_slot": initial_slot}
	var added_entry := entry.duplicate(true)
	next_loadout.append(added_entry)
	return {
		"action": "add",
		"loadout": next_loadout,
		"entry": added_entry.duplicate(true),
		"initial_slot": initial_slot,
	}


func sortie_starter_plan(loadout: Array, entry: Dictionary, existing_position: int, sortie_cap: int) -> Dictionary:
	var next_loadout := loadout.duplicate(true)
	var role_key := String(entry.get("role", "hero"))
	if existing_position >= 0:
		if existing_position >= next_loadout.size():
			return {"action": "none", "loadout": next_loadout, "initial_slot": 0, "initial_role": role_key}
		return {
			"action": "set",
			"loadout": next_loadout,
			"initial_slot": existing_position,
			"initial_role": role_key,
		}
	if next_loadout.size() >= maxi(0, sortie_cap):
		return {"action": "full", "loadout": next_loadout, "initial_slot": -1, "initial_role": role_key}
	var added_entry := entry.duplicate(true)
	next_loadout.append(added_entry)
	return {
		"action": "append",
		"loadout": next_loadout,
		"entry": added_entry.duplicate(true),
		"initial_slot": next_loadout.size() - 1,
		"initial_role": role_key,
	}


func sortie_active_index_plan(entry: Dictionary, valid_roster: bool) -> Dictionary:
	if not valid_roster:
		return {"action": "none"}
	var role_key := String(entry.get("role", "hero"))
	var unit_index := int(entry.get("index", 0))
	return {
		"action": "set",
		"role_key": role_key,
		"unit_index": unit_index,
		"initial_role": role_key,
	}


func sortie_position(loadout: Array, role_key: String, unit_index: int) -> int:
	for i in range(loadout.size()):
		if not (loadout[i] is Dictionary):
			continue
		var entry: Dictionary = loadout[i]
		if String(entry.get("role", "")) == role_key and int(entry.get("index", -1)) == unit_index:
			return i
	return -1


func team_sortie_order(loadout: Array, roster_sizes: Dictionary, role_order: Array, sortie_cap: int) -> Array:
	var order: Array = []
	var cap := maxi(0, sortie_cap)
	if cap <= 0:
		return order
	for raw_entry in loadout:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		if not valid_roster_entry(entry, roster_sizes, role_order):
			continue
		order.append(entry.duplicate(true))
		if order.size() >= cap:
			break
	return order


func starter_sortie_entry(loadout: Array, initial_slot: int, fallback_role: String, active_indices: Dictionary) -> Dictionary:
	if not loadout.is_empty():
		var slot_index := clampi(initial_slot, 0, loadout.size() - 1)
		if loadout[slot_index] is Dictionary:
			return Dictionary(loadout[slot_index]).duplicate(true)
	var role_key := String(fallback_role)
	return {"role": role_key, "index": int(active_indices.get(role_key, 0))}


func sortie_role_counts(loadout: Array, role_order: Array) -> Dictionary:
	var counts := {}
	for raw_role_key in role_order:
		counts[String(raw_role_key)] = 0
	for raw_entry in loadout:
		if not (raw_entry is Dictionary):
			continue
		var role_key := String(Dictionary(raw_entry).get("role", ""))
		if counts.has(role_key):
			counts[role_key] = int(counts[role_key]) + 1
	return counts


func sortie_has_required_roles(loadout: Array, role_order: Array) -> bool:
	var counts := sortie_role_counts(loadout, role_order)
	for raw_role_key in role_order:
		var role_key := String(raw_role_key)
		if int(counts.get(role_key, 0)) <= 0:
			return false
	return true


func ai_sortie_score(entry: Dictionary, stats: Dictionary, starter_score: bool) -> float:
	var role_key := String(entry.get("role", "hero"))
	var score := float(stats.get("health", 0)) * 0.12
	score += float(stats.get("normal_damage", 0)) * 3.6 + float(stats.get("active_damage", 0)) * 2.2 + float(stats.get("armor_damage", 0)) * 1.5
	score += float(stats.get("speed", 0.0)) * 34.0 + float(stats.get("data_security", 1.0)) * 14.0
	score -= float(stats.get("deploy_cost", stats.get("cost", 0))) * 0.1
	if role_key == "hero":
		score += 90.0
	elif role_key == "puppet":
		score += 64.0 + float(stats.get("group_count", 1)) * 8.0
	else:
		score += 54.0 + float(stats.get("aura_range", 0.0)) * 42.0 + float(stats.get("pulse_interval", 1.0)) * -8.0
	if starter_score:
		score += 260.0 - float(stats.get("cost", 999)) * 0.65
	return score


func entry_is_selected(entry: Dictionary, selected: Array) -> bool:
	var ref := _entry_ref_from_values(String(entry.get("role", "hero")), int(entry.get("index", 0)))
	for raw_selected_entry in selected:
		if raw_selected_entry is Dictionary:
			var selected_entry: Dictionary = raw_selected_entry
			if _entry_ref_from_values(String(selected_entry.get("role", "hero")), int(selected_entry.get("index", 0))) == ref:
				return true
	return false


func sortie_entry_battle_legality(context: Dictionary) -> bool:
	if not bool(context.get("valid_roster", false)):
		return false
	if bool(context.get("require_starter_cost", false)) and not bool(context.get("starter_cost_valid", false)):
		return false
	var role_key := String(context.get("role_key", "hero"))
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	if float(stats.get("length", 0.0)) > 4.5:
		return false
	if bool(context.get("role_uses_body_board", false)) and not bool(context.get("module_material_valid", true)):
		return false
	if String(context.get("topology_note", "")).begins_with("INVALID"):
		return false
	if String(context.get("unit_legality_note", "")).begins_with("INVALID"):
		return false
	for note_key in ["joint_momentum_note", "slot_payload_note", "drive_note", "stiffness_note"]:
		if role_key == "barrier" and note_key in ["slot_payload_note", "drive_note"]:
			continue
		if String(stats.get(note_key, "")).begins_with("INVALID"):
			return false
	return true


func all_roster_order(roster_sizes: Dictionary, role_order: Array) -> Array:
	var order: Array = []
	var max_units := 0
	for raw_role_key in role_order:
		var role_key := String(raw_role_key)
		max_units = maxi(max_units, maxi(0, int(roster_sizes.get(role_key, 0))))
	for unit_index in range(max_units):
		for raw_role_key in role_order:
			var role_key := String(raw_role_key)
			if unit_index < maxi(0, int(roster_sizes.get(role_key, 0))):
				order.append({"role": role_key, "index": unit_index})
	return order


func roster_unit_total(roster_sizes: Dictionary, role_order: Array) -> int:
	var total := 0
	for raw_role_key in role_order:
		var role_key := String(raw_role_key)
		total += maxi(0, int(roster_sizes.get(role_key, 0)))
	return total


func default_sortie_loadout(roster_order: Array, sortie_cap: int) -> Array:
	var loadout: Array = []
	var limit := mini(roster_order.size(), maxi(0, sortie_cap))
	for i in range(limit):
		if not (roster_order[i] is Dictionary):
			continue
		loadout.append(Dictionary(roster_order[i]).duplicate(true))
	return loadout


func default_summon_pair_bindings(default_slots: Array, sortie_cap: int) -> Array:
	var bindings: Array = []
	var limit := mini(maxi(0, sortie_cap), default_slots.size())
	for i in range(limit):
		var pair: Array = Array(default_slots[i]).duplicate(true) if default_slots[i] is Array else []
		bindings.append(pair)
	return bindings


func summon_pair_bindings_plan(raw_bindings: Array, default_slots: Array, sortie_cap: int, attack_key_count: int) -> Array:
	var fixed: Array = []
	for i in range(maxi(0, sortie_cap)):
		var pair: Array = []
		if i < raw_bindings.size() and raw_bindings[i] is Array:
			pair = Array(raw_bindings[i]).duplicate(true)
		elif i < default_slots.size() and default_slots[i] is Array:
			pair = Array(default_slots[i]).duplicate(true)
		fixed.append(_normalized_summon_pair(pair, attack_key_count))
	return fixed


func summon_pair_clear_intent(bindings: Array, slot_index: int) -> Dictionary:
	var next_bindings := bindings.duplicate(true)
	if slot_index < 0 or slot_index >= next_bindings.size():
		return {"action": "none", "bindings": next_bindings, "slot_index": slot_index}
	next_bindings[slot_index] = []
	return {"action": "clear", "bindings": next_bindings, "slot_index": slot_index}


func summon_pair_cycle_intent(bindings: Array, slot_index: int, direction: int, default_slots: Array, _attack_key_count: int) -> Dictionary:
	var next_bindings := bindings.duplicate(true)
	if default_slots.is_empty() or slot_index < 0 or slot_index >= next_bindings.size():
		return {"action": "none", "bindings": next_bindings, "pair": [], "candidate_index": -1}
	var current_pair: Array = Array(next_bindings[slot_index]) if next_bindings[slot_index] is Array else []
	var current_key := _summon_pair_key(current_pair)
	var start := 0
	for i in range(default_slots.size()):
		var default_pair: Array = Array(default_slots[i]) if default_slots[i] is Array else []
		if _summon_pair_key(default_pair) == current_key:
			start = i
			break
	for offset in range(1, default_slots.size() + 1):
		var candidate_index := _wrapped_index(start + direction * offset, default_slots.size())
		var candidate: Array = Array(default_slots[candidate_index]).duplicate(true)
		if _summon_pair_used_by_other(next_bindings, candidate, slot_index):
			continue
		next_bindings[slot_index] = candidate
		return {
			"action": "set",
			"bindings": next_bindings,
			"pair": candidate,
			"candidate_index": candidate_index,
		}
	return {"action": "none", "bindings": next_bindings, "pair": [], "candidate_index": -1}


func summon_portal_selection_intent(input_vector: Vector2, current_index: int, portal_count: int, cycle_direction: int = 1) -> Dictionary:
	if portal_count <= 0:
		return {"portal_index": 0, "selection": "none", "direct": false, "changed": false}
	var current := clampi(current_index, 0, portal_count - 1)
	var direct := input_vector.length() >= 0.34
	var next_index := portal_index_from_vector(input_vector, current, portal_count) if direct else _wrapped_index(current + cycle_direction, portal_count)
	return {
		"portal_index": next_index,
		"selection": "direct" if direct else "cycle",
		"direct": direct,
		"changed": next_index != current,
	}


func portal_index_from_vector(input_vector: Vector2, fallback_index: int, portal_count: int) -> int:
	if portal_count <= 0:
		return 0
	if input_vector.length() < 0.34:
		return clampi(fallback_index, 0, portal_count - 1)
	var x := input_vector.x
	var y := input_vector.y
	if y < -0.35:
		if x < -0.35:
			return 0
		if x > 0.35:
			return mini(2, portal_count - 1)
		return mini(1, portal_count - 1)
	if y > 0.35:
		if x < -0.35:
			return mini(5, portal_count - 1)
		if x > 0.35:
			return mini(7, portal_count - 1)
		return mini(6, portal_count - 1)
	if x < -0.35:
		return mini(3, portal_count - 1)
	if x > 0.35:
		return mini(4, portal_count - 1)
	return clampi(fallback_index, 0, portal_count - 1)


func _normalized_summon_pair(pair: Array, attack_key_count: int) -> Array:
	if attack_key_count <= 0 or pair.size() < 2:
		return []
	var a := clampi(int(pair[0]), 1, attack_key_count)
	var b := clampi(int(pair[1]), 1, attack_key_count)
	if a == b:
		return []
	return [mini(a, b), maxi(a, b)]


func _entry_ref_from_values(role_key: String, unit_index: int) -> String:
	return "%s:%d" % [role_key, unit_index]


func _summon_pair_key(pair: Array) -> String:
	if pair.size() < 2:
		return ""
	return "%d:%d" % [int(pair[0]), int(pair[1])]


func _summon_pair_used_by_other(bindings: Array, pair: Array, slot_index: int) -> bool:
	var key := _summon_pair_key(pair)
	if key == "":
		return false
	for i in range(bindings.size()):
		if i == slot_index:
			continue
		var existing: Array = Array(bindings[i]) if bindings[i] is Array else []
		if _summon_pair_key(existing) == key:
			return true
	return false


func _wrapped_index(value: int, size: int) -> int:
	if size <= 0:
		return 0
	var wrapped := value % size
	if wrapped < 0:
		wrapped += size
	return wrapped


func source_rule_for_condition(raw_rules, condition: String) -> Dictionary:
	if not (raw_rules is Dictionary):
		return {}
	var rules: Dictionary = raw_rules
	if rules.has(condition):
		var exact = rules.get(condition, {})
		return Dictionary(exact).duplicate(true) if exact is Dictionary else {}
	var fallback = rules.get("default", {})
	return Dictionary(fallback).duplicate(true) if fallback is Dictionary else {}


func default_puppet_attack_modules(unit_index: int, attack_group_count: int, disabled_modules: Array) -> Array:
	var modules: Array = []
	if attack_group_count <= 0:
		return modules
	var preferred := clampi(unit_index % attack_group_count, 0, attack_group_count - 1)
	if not _is_disabled(disabled_modules, preferred):
		modules.append(preferred)
	for attack_index in range(attack_group_count):
		if attack_index == preferred:
			continue
		if not _is_disabled(disabled_modules, attack_index):
			modules.append(attack_index)
	return modules


func puppet_condition(context: Dictionary) -> String:
	if bool(context.get("uses_heat", false)):
		var heat_capacity := maxf(1.0, float(context.get("heat_capacity", 100.0)))
		if bool(context.get("overheated", false)) or float(context.get("heat", 0.0)) >= heat_capacity * 0.78:
			return "self_overheat"
	if not bool(context.get("hero_live", false)):
		return "hero_absent"
	if bool(context.get("target_live", false)) and float(context.get("target_projectile_signal", 0.0)) > 0.0:
		return "enemy_shooting"
	var delta_ring_abs := absf(float(context.get("delta_ring", 0.0)))
	if delta_ring_abs > float(context.get("hold_range", 0.82)) + 0.38:
		return "enemy_far"
	if delta_ring_abs < 0.36 + float(context.get("target_radius", 0.2)) * 0.4:
		return "enemy_close"
	return "default"


func puppet_move_intent(context: Dictionary) -> Dictionary:
	var unit: Dictionary = Dictionary(context.get("unit", {}))
	var target: Dictionary = Dictionary(context.get("target", {}))
	var stats: Dictionary = Dictionary(unit.get("stats", {}))
	var delta := float(context.get("delta", 0.0))
	var unit_index := int(context.get("unit_index", 0))
	var group_size := maxi(1, int(context.get("group_size", 1)))
	var ring_length := maxf(0.001, float(context.get("ring_length", 1.0)))
	var half_height := maxf(0.001, float(context.get("battle_half_height", 1.0)))
	var delta_ring := float(context.get("delta_ring", 0.0))
	var delta_lane := float(context.get("delta_lane", 0.0))
	var target_vec := Vector2(delta_ring, delta_lane)
	var move := target_vec.normalized() if target_vec.length() > 0.01 else Vector2(float(unit.get("facing", 1.0)), 0.0)
	var ai_kind := String(stats.get("ai", "line"))
	var phase := float(unit.get("phase", 0.0)) + delta * (1.8 + float(unit_index) * 0.17)

	if float(context.get("blind_strength", 0.0)) > 0.08:
		var blind_escape: Vector2 = context.get("blind_escape_vector", Vector2.ZERO) if context.get("blind_escape_vector", Vector2.ZERO) is Vector2 else Vector2.ZERO
		return {"move": (blind_escape + Vector2(-signf(delta_ring) * 0.22, 0.0)).limit_length(1.0), "phase": phase, "ai_kind": ai_kind}

	if ai_kind == "drone_cloud":
		var orbit := float(stats.get("orbit_radius", 1.02))
		var angle := phase * 1.55 + TAU * float(unit_index) / maxf(1.0, float(group_size))
		var anchor := _live_or_fallback(Dictionary(context.get("hero", {})), target)
		var desired_ring := wrapf(float(anchor.get("ring", 0.0)) + cos(angle) * orbit, 0.0, ring_length)
		var desired_lane := clampf(float(anchor.get("lane", 0.0)) + sin(angle) * orbit * 0.72, -half_height, half_height)
		move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.4, -1.0, 1.0))
		if absf(delta_ring) < float(stats.get("hold_range", 1.2)):
			move += Vector2(signf(delta_ring) * 0.35, clampf(delta_lane * 0.8, -0.5, 0.5))
	elif ai_kind == "figure8":
		move = Vector2(sin(phase), sin(phase * 2.0))
		if absf(delta_ring) > 1.4:
			move.x += signf(delta_ring) * 0.8
	elif ai_kind == "volley":
		move.y = clampf(delta_lane * 1.4, -0.8, 0.8)
		if absf(delta_ring) < float(stats.get("hold_range", 0.9)):
			move.x = -signf(delta_ring) * 0.45
	elif ai_kind == "ranged_pack" or ai_kind == "siege_battery":
		var keep_range := float(stats.get("source_keep_range", stats.get("hold_range", 1.2)))
		var side := -1.0 if unit_index % 2 == 0 else 1.0
		if absf(delta_ring) < keep_range * 0.72:
			move = Vector2(-signf(delta_ring), clampf(-delta_lane * 1.2 + side * 0.34, -1.0, 1.0))
		elif absf(delta_ring) > keep_range * 1.18:
			move = Vector2(signf(delta_ring), clampf(delta_lane * 1.1 + side * 0.22, -1.0, 1.0))
		else:
			move = Vector2(side * 0.18, clampf(delta_lane * 1.3 + sin(phase + float(unit_index)) * 0.35, -1.0, 1.0))
	elif ai_kind == "execution_swarm":
		var side := -1.0 if unit_index % 2 == 0 else 1.0
		move = Vector2(signf(delta_ring), clampf(delta_lane * 1.75 + side * 0.45, -1.0, 1.0))
		if absf(delta_ring) < 0.48:
			move.x = side * 0.28
	elif ai_kind == "interceptor_screen":
		var own_hero := Dictionary(context.get("hero", {}))
		if _snap_live(own_hero):
			var hero_to_target := _ring_delta(float(own_hero.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length)
			var screen_offset := (float(unit_index) - float(group_size - 1) * 0.5) * 0.24
			var desired_ring := wrapf(float(own_hero.get("ring", 0.0)) + hero_to_target * 0.38, 0.0, ring_length)
			var desired_lane := clampf(lerpf(float(own_hero.get("lane", 0.0)), float(target.get("lane", 0.0)), 0.46) + screen_offset, -half_height, half_height)
			move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.4, -1.0, 1.0))
		else:
			move = Vector2(signf(delta_ring), clampf(delta_lane * 1.2, -1.0, 1.0))
	elif ai_kind == "vanguard_cover":
		var guard_anchor := Dictionary(context.get("guard_anchor", {}))
		if _snap_live(guard_anchor):
			var anchor_to_target := _ring_delta(float(guard_anchor.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length)
			var screen_offset := (float(unit_index) - float(group_size - 1) * 0.5) * 0.2
			var desired_ring := wrapf(float(guard_anchor.get("ring", 0.0)) + anchor_to_target * 0.48, 0.0, ring_length)
			var desired_lane := clampf(lerpf(float(guard_anchor.get("lane", 0.0)), float(target.get("lane", 0.0)), 0.5) + screen_offset, -half_height, half_height)
			move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.6, -1.0, 1.0))
			if absf(delta_ring) < float(stats.get("hold_range", 0.74)):
				move += Vector2(signf(delta_ring) * 0.28, clampf(delta_lane * 0.9, -0.45, 0.45))
		else:
			move = Vector2(signf(delta_ring), clampf(delta_lane * 1.45, -1.0, 1.0))
	elif ai_kind == "guard_orbit":
		var guard_hero := Dictionary(context.get("hero", {}))
		var anchor_ring := float(unit.get("ring", 0.0))
		var anchor_lane := float(unit.get("lane", 0.0))
		if _snap_live(guard_hero):
			var orbit := float(stats.get("orbit_radius", 0.42))
			var angle := phase + TAU * float(unit_index) / maxf(1.0, float(group_size))
			anchor_ring = wrapf(float(guard_hero.get("ring", 0.0)) + cos(angle) * orbit, 0.0, ring_length)
			anchor_lane = clampf(float(guard_hero.get("lane", 0.0)) + sin(angle) * orbit * 0.8, -half_height, half_height)
		move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), anchor_ring, ring_length)), clampf((anchor_lane - float(unit.get("lane", 0.0))) * 2.4, -1.0, 1.0))
		if absf(delta_ring) < 0.72:
			move += Vector2(signf(delta_ring) * 0.45, clampf(delta_lane * 1.2, -0.5, 0.5))
	elif ai_kind == "pincer":
		var side := -1.0 if unit_index % 2 == 0 else 1.0
		var flank := float(stats.get("flank_width", 0.66)) * side
		move = Vector2(signf(delta_ring), clampf((float(target.get("lane", 0.0)) + flank - float(unit.get("lane", 0.0))) * 2.0, -1.0, 1.0))
		if absf(delta_ring) < 0.72:
			move.x = -side * 0.35
	elif ai_kind == "screen_wall":
		var screen_hero := Dictionary(context.get("hero", {}))
		var anchor_ring := float(unit.get("ring", 0.0))
		var anchor_lane := float(unit.get("lane", 0.0))
		if _snap_live(screen_hero):
			anchor_ring = wrapf(float(screen_hero.get("ring", 0.0)) + _ring_delta(float(screen_hero.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length) * 0.42, 0.0, ring_length)
			var spread := (float(unit_index) - float(group_size - 1) * 0.5) * 0.28
			anchor_lane = clampf(lerpf(float(screen_hero.get("lane", 0.0)), float(target.get("lane", 0.0)), 0.5) + spread, -half_height, half_height)
		move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), anchor_ring, ring_length)), clampf((anchor_lane - float(unit.get("lane", 0.0))) * 2.3, -1.0, 1.0))
	elif ai_kind == "formation_xi":
		var formation_hero := Dictionary(context.get("hero", {}))
		var rows := [-0.72, -0.42, -0.14, 0.14, 0.42, 0.72]
		var columns := [-0.82, -0.46, 0.0, 0.46, 0.82]
		var col := unit_index % columns.size()
		var row := int(floor(float(unit_index) / float(columns.size()))) % rows.size()
		var anchor_ring := float(target.get("ring", 0.0)) - signf(delta_ring) * float(stats.get("hold_range", 1.2))
		var anchor_lane := float(target.get("lane", 0.0))
		if _snap_live(formation_hero):
			anchor_ring = lerpf(float(formation_hero.get("ring", 0.0)), float(target.get("ring", 0.0)), 0.55)
			anchor_lane = float(formation_hero.get("lane", 0.0)) * 0.42 + float(target.get("lane", 0.0)) * 0.58
		var desired_ring := wrapf(anchor_ring + float(columns[col]) * float(stats.get("flank_width", 0.86)), 0.0, ring_length)
		var desired_lane := clampf(anchor_lane + float(rows[row]) * 0.54, -half_height, half_height)
		move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.15, -1.0, 1.0))
		if absf(delta_ring) < 0.44:
			move += Vector2(-signf(delta_ring) * 0.22, clampf(delta_lane * 0.52, -0.4, 0.4))
	elif ai_kind == "mine_dance":
		var orbit := float(stats.get("orbit_radius", 0.62))
		var angle := phase + TAU * float(unit_index) / maxf(1.0, float(group_size))
		var desired_ring := wrapf(float(target.get("ring", 0.0)) + cos(angle) * orbit, 0.0, ring_length)
		var desired_lane := clampf(float(target.get("lane", 0.0)) + sin(angle) * orbit, -half_height, half_height)
		move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.1, -1.0, 1.0))

	var source_rule: Dictionary = Dictionary(context.get("source_rule", {}))
	if not source_rule.is_empty():
		move = _source_move_vector(context, phase, String(source_rule.get("move", "approach")))
	var raw_terrain_plan = context.get("terrain_path_plan", {})
	var terrain_plan: Dictionary = raw_terrain_plan if raw_terrain_plan is Dictionary else {}
	move = _terrain_path_adjusted_move(move, terrain_plan)
	return {
		"move": move.limit_length(1.0),
		"phase": phase,
		"ai_kind": ai_kind,
		"terrain_path_plan": terrain_plan.duplicate(true),
		"terrain_path_mode": String(terrain_plan.get("mode", "clear")),
		"terrain_path_feature_id": String(terrain_plan.get("feature_id", "")),
	}


func puppet_attack_intent(context: Dictionary) -> Dictionary:
	var delta := float(context.get("delta", 0.0))
	var delta_ring := float(context.get("delta_ring", 0.0))
	var delta_lane := float(context.get("delta_lane", 0.0))
	var ai_kind := String(context.get("ai_kind", "line"))
	if bool(context.get("role_switch", false)) and (not bool(context.get("hero_live", false)) or absf(delta_ring) <= float(context.get("switch_trigger_range", 0.62))):
		return {"action": "role_switch"}
	if float(context.get("jammed_timer", 0.0)) > 0.0:
		return {"action": "set_timer", "fire_timer": 0.28, "reason": "jammed"}
	var unit_index := int(context.get("unit_index", 0))
	var cadence := _puppet_cadence(ai_kind, unit_index)
	var current_fire_timer := float(context.get("fire_timer", cadence))
	if not bool(context.get("has_fire_timer", true)):
		current_fire_timer = cadence
	var fire_timer := maxf(0.0, current_fire_timer - delta)
	if fire_timer > 0.0:
		return {"action": "cooldown", "fire_timer": fire_timer}
	var sequence: Array = Array(context.get("sequence", ["normal"]))
	if sequence.is_empty():
		sequence = ["normal"]
	var default_modules: Array = Array(context.get("default_modules", []))
	var modules: Array = Array(context.get("modules", default_modules))
	if modules.is_empty():
		modules = default_modules
	if modules.is_empty():
		return {"action": "set_timer", "fire_timer": 0.36 + cadence, "reason": "no_modules"}
	var step := int(context.get("sequence_step", 0))
	var action_kind := String(sequence[step % sequence.size()])
	var groups: Array = Array(context.get("groups", []))
	var attack_count := maxi(1, int(context.get("attack_group_count", groups.size())))
	var disabled_modules: Array = Array(context.get("disabled_modules", []))
	var preference := String(context.get("source_attack_preference", ""))
	var attack_index := _source_attack_index_for_step(groups, modules, step, preference, disabled_modules, attack_count)
	var group := _group_by_index(groups, attack_index)
	if _is_disabled(disabled_modules, attack_index):
		return {"action": "advance_step", "sequence_step": step + 1, "fire_timer": 0.36 + cadence, "reason": "disabled"}
	if not _puppet_attack_reaches(group, action_kind, ai_kind, delta_ring, delta_lane, float(context.get("battle_half_height", 1.0))):
		for raw_candidate in modules:
			var candidate_index := clampi(int(raw_candidate), 0, attack_count - 1)
			if _is_disabled(disabled_modules, candidate_index):
				continue
			var candidate_group := _group_by_index(groups, candidate_index)
			if _puppet_attack_reaches(candidate_group, action_kind, ai_kind, delta_ring, delta_lane, float(context.get("battle_half_height", 1.0))):
				attack_index = candidate_index
				group = candidate_group
				break
	if _puppet_attack_reaches(group, action_kind, ai_kind, delta_ring, delta_lane, float(context.get("battle_half_height", 1.0))):
		return {
			"action": "fire",
			"attack_index": attack_index,
			"action_kind": action_kind,
			"sequence_step": step + 1,
			"fire_timer": 0.42 + cadence,
			"cadence": cadence,
			"group": group.duplicate(true),
		}
	return {"action": "none", "fire_timer": fire_timer}


func barrier_logic_intents(context: Dictionary) -> Array:
	var logic := String(context.get("logic", "pulse"))
	var delta := float(context.get("delta", 0.0))
	var pulse_timer := maxf(0.0, float(context.get("pulse_timer", 0.0)) - delta)
	var enemy_inside := bool(context.get("enemy_inside", false))
	match logic:
		"heat_well":
			return [{"action": "heat_well_enemies"}]
		"caustic_field":
			return [{"action": "caustic_field_enemies"}]
		"coolant_veil":
			return [{"action": "coolant_veil_allies"}]
		"drag_net":
			return [{"action": "drag_net_enemies"}]
		"damage_amp":
			return [{"action": "damage_amp_allies", "mult_default": 1.2}]
		"riposte_mirror":
			if enemy_inside and pulse_timer <= 0.0:
				return [{"action": "set_pulse_timer", "timer": float(context.get("pulse_interval", 1.05))}, {"action": "pulse"}]
			return [{"action": "set_pulse_timer", "timer": pulse_timer}]
		"galaxy_castle":
			var intents: Array = [
				{"action": "damage_amp_allies", "mult_default": 1.12},
				{"action": "galaxy_castle_enemies"},
			]
			if pulse_timer <= 0.0:
				intents.append({"action": "set_pulse_timer", "timer": float(context.get("pulse_interval", 0.8))})
				intents.append({"action": "pulse"})
			else:
				intents.append({"action": "set_pulse_timer", "timer": pulse_timer})
			return intents
		"gravity_vector", "structure_only":
			return []
	return [{"action": "pulse"}]


func command_diagnostics(context: Dictionary) -> Dictionary:
	var raw_source_rule = context.get("source_rule", {})
	var source_rule: Dictionary = raw_source_rule if raw_source_rule is Dictionary else {}
	var role_switch_target := String(context.get("role_switch_target", context.get("role_switch", "")))
	return {
		"ai_kind": String(context.get("ai_kind", "")),
		"source_condition": String(context.get("source_condition", "")),
		"source_move_kind": String(context.get("source_move_kind", source_rule.get("move", ""))),
		"source_attack_preference": String(context.get("source_attack_preference", "")),
		"fire_timer": maxf(0.0, float(context.get("fire_timer", 0.0))),
		"sequence_step": maxi(0, int(context.get("sequence_step", 0))),
		"sequence_size": maxi(0, int(context.get("sequence_size", Array(context.get("sequence", [])).size()))),
		"movement_mode": String(context.get("movement_mode", "")),
		"movement_gate_reason": String(context.get("movement_gate_reason", "")),
		"role_switch_configured": bool(context.get("role_switch_configured", role_switch_target != "")),
		"role_switch_target": role_switch_target,
		"source_code_entry_id": String(context.get("source_code_entry_id", "")),
		"source_code_name": String(context.get("source_code_name", "")),
		"source_code_rejection_reason": String(context.get("source_code_rejection_reason", "")),
	}


func _terrain_path_adjusted_move(move: Vector2, terrain_plan: Dictionary) -> Vector2:
	if terrain_plan.is_empty():
		return move
	var mode := String(terrain_plan.get("mode", "clear"))
	if mode == "" or mode == "clear":
		return move
	var recommended = terrain_plan.get("recommended_direction", Vector2.ZERO)
	if not (recommended is Vector2):
		return move
	var direction := Vector2(recommended)
	if direction.length() <= 0.04:
		return move
	direction = direction.normalized()
	if bool(terrain_plan.get("blocked", false)) or mode == "hazard":
		return (move.limit_length(1.0) * 0.45 + direction * 0.75).limit_length(1.0)
	if mode == "bridged" or mode == "route":
		var base := move.limit_length(1.0)
		if base.length() <= 0.04:
			return direction
		var route_pull := 0.28 if base.normalized().dot(direction) < 0.35 else 0.14
		return (base + direction * route_pull).limit_length(1.0)
	return move


func _source_move_vector(context: Dictionary, phase: float, move_kind: String) -> Vector2:
	var unit: Dictionary = Dictionary(context.get("unit", {}))
	var target: Dictionary = Dictionary(context.get("target", {}))
	var stats: Dictionary = Dictionary(unit.get("stats", {}))
	var unit_index := int(context.get("unit_index", 0))
	var group_size := maxi(1, int(context.get("group_size", 1)))
	var ring_length := maxf(0.001, float(context.get("ring_length", 1.0)))
	var half_height := maxf(0.001, float(context.get("battle_half_height", 1.0)))
	var delta_ring := _ring_delta(float(unit.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length)
	var delta_lane := float(target.get("lane", 0.0)) - float(unit.get("lane", 0.0))
	match move_kind:
		"retreat":
			return Vector2(-signf(delta_ring), clampf(-delta_lane * 1.4, -1.0, 1.0))
		"kite":
			var keep_range := float(stats.get("source_keep_range", stats.get("hold_range", 1.1)))
			var side := -1.0 if unit_index % 2 == 0 else 1.0
			if absf(delta_ring) < keep_range:
				return Vector2(-signf(delta_ring), clampf(-delta_lane * 1.25 + side * 0.32, -1.0, 1.0))
			return Vector2(side * 0.18, clampf(delta_lane * 1.05 + sin(phase + float(unit_index)) * 0.42, -1.0, 1.0))
		"keep_range":
			var keep_range := float(stats.get("source_keep_range", stats.get("hold_range", 1.2)))
			if absf(delta_ring) < keep_range * 0.74:
				return Vector2(-signf(delta_ring), clampf(-delta_lane * 1.15, -1.0, 1.0))
			if absf(delta_ring) > keep_range * 1.2:
				return Vector2(signf(delta_ring), clampf(delta_lane * 1.2, -1.0, 1.0))
			return Vector2(0.0, clampf(delta_lane * 1.45 + sin(phase + float(unit_index)) * 0.32, -1.0, 1.0))
		"screen":
			var own_hero := Dictionary(context.get("hero", {}))
			if _snap_live(own_hero):
				var hero_to_target := _ring_delta(float(own_hero.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length)
				var spread := (float(unit_index) - float(group_size - 1) * 0.5) * 0.22
				var desired_ring := wrapf(float(own_hero.get("ring", 0.0)) + hero_to_target * 0.38, 0.0, ring_length)
				var desired_lane := clampf(lerpf(float(own_hero.get("lane", 0.0)), float(target.get("lane", 0.0)), 0.46) + spread, -half_height, half_height)
				return Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.3, -1.0, 1.0))
			return Vector2(signf(delta_ring), clampf(delta_lane * 1.2, -1.0, 1.0))
		"intercept":
			return _guard_anchor_move(context, 0.56, 0.52, 0.18, 2.7, Vector2(signf(delta_ring), clampf(delta_lane * 1.45, -1.0, 1.0)))
		"cover_group":
			var guard_anchor := Dictionary(context.get("guard_anchor", {}))
			if _snap_live(guard_anchor):
				var orbit := float(stats.get("orbit_radius", 0.46))
				var angle := phase + TAU * float(unit_index) / maxf(1.0, float(group_size))
				var desired_ring := wrapf(float(guard_anchor.get("ring", 0.0)) + cos(angle) * orbit + _ring_delta(float(guard_anchor.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length) * 0.22, 0.0, ring_length)
				var desired_lane := clampf(float(guard_anchor.get("lane", 0.0)) + sin(angle) * orbit * 0.8 + (float(target.get("lane", 0.0)) - float(guard_anchor.get("lane", 0.0))) * 0.22, -half_height, half_height)
				return Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.3, -1.0, 1.0))
			return Vector2(signf(delta_ring), clampf(delta_lane * 1.1, -1.0, 1.0))
		"cover_retreat":
			var guard_anchor := Dictionary(context.get("guard_anchor", {}))
			if _snap_live(guard_anchor):
				var away_from_target := -signf(_ring_delta(float(guard_anchor.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length))
				var desired_ring := wrapf(float(guard_anchor.get("ring", 0.0)) + away_from_target * 0.28, 0.0, ring_length)
				var desired_lane := clampf(float(guard_anchor.get("lane", 0.0)) - signf(float(target.get("lane", 0.0)) - float(guard_anchor.get("lane", 0.0))) * 0.22, -half_height, half_height)
				return Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.0, -1.0, 1.0))
			return Vector2(-signf(delta_ring), clampf(-delta_lane * 1.2, -1.0, 1.0))
		"hunt":
			var side := -1.0 if unit_index % 2 == 0 else 1.0
			return Vector2(signf(delta_ring), clampf(delta_lane * 1.7 + side * 0.38, -1.0, 1.0))
		"hold":
			return Vector2(0.0, clampf(delta_lane * 1.2, -0.7, 0.7))
		"orbit":
			var orbit := float(stats.get("orbit_radius", 0.54))
			var angle := phase + TAU * float(unit_index) / maxf(1.0, float(group_size))
			var desired_ring := wrapf(float(target.get("ring", 0.0)) + cos(angle) * orbit, 0.0, ring_length)
			var desired_lane := clampf(float(target.get("lane", 0.0)) + sin(angle) * orbit, -half_height, half_height)
			return Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.0, -1.0, 1.0))
		"flank":
			var side := -1.0 if unit_index % 2 == 0 else 1.0
			var lane_goal := clampf(float(target.get("lane", 0.0)) + side * float(stats.get("flank_width", 0.58)), -half_height, half_height)
			return Vector2(signf(delta_ring), clampf((lane_goal - float(unit.get("lane", 0.0))) * 2.0, -1.0, 1.0))
	return Vector2(signf(delta_ring), clampf(delta_lane * 2.0, -1.0, 1.0))


func _guard_anchor_move(context: Dictionary, ring_factor: float, lane_lerp: float, spread_mult: float, lane_gain: float, fallback: Vector2) -> Vector2:
	var guard_anchor := Dictionary(context.get("guard_anchor", {}))
	if not _snap_live(guard_anchor):
		return fallback
	var unit: Dictionary = Dictionary(context.get("unit", {}))
	var target: Dictionary = Dictionary(context.get("target", {}))
	var ring_length := maxf(0.001, float(context.get("ring_length", 1.0)))
	var half_height := maxf(0.001, float(context.get("battle_half_height", 1.0)))
	var unit_index := int(context.get("unit_index", 0))
	var group_size := maxi(1, int(context.get("group_size", 1)))
	var anchor_to_target := _ring_delta(float(guard_anchor.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length)
	var spread := (float(unit_index) - float(group_size - 1) * 0.5) * spread_mult
	var desired_ring := wrapf(float(guard_anchor.get("ring", 0.0)) + anchor_to_target * ring_factor, 0.0, ring_length)
	var desired_lane := clampf(lerpf(float(guard_anchor.get("lane", 0.0)), float(target.get("lane", 0.0)), lane_lerp) + spread, -half_height, half_height)
	return Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * lane_gain, -1.0, 1.0))


func _source_attack_index_for_step(groups: Array, modules: Array, step: int, preference: String, disabled_modules: Array, attack_count: int) -> int:
	if modules.is_empty():
		return 0
	var fallback := clampi(int(modules[step % modules.size()]), 0, attack_count - 1)
	if preference == "":
		return fallback
	var ordered: Array = []
	for offset in range(modules.size()):
		ordered.append(clampi(int(modules[(step + offset) % modules.size()]), 0, attack_count - 1))
	if preference in ["ranged_first", "finish_first"]:
		for attack_index in ordered:
			var group := _group_by_index(groups, int(attack_index))
			if bool(group.get("projectile", false)) and not _is_disabled(disabled_modules, int(attack_index)):
				return int(attack_index)
	if preference == "melee_first":
		for attack_index in ordered:
			var group := _group_by_index(groups, int(attack_index))
			if not bool(group.get("projectile", false)) and not _is_disabled(disabled_modules, int(attack_index)):
				return int(attack_index)
	if preference == "intercept_first":
		for attack_index in ordered:
			var group := _group_by_index(groups, int(attack_index))
			if (String(group.get("damage_type", "blunt")) == "blunt" or String(group.get("skill_state", "")) == "armor") and not _is_disabled(disabled_modules, int(attack_index)):
				return int(attack_index)
	for attack_index in ordered:
		if not _is_disabled(disabled_modules, int(attack_index)):
			return int(attack_index)
	return fallback


func _puppet_attack_reaches(group: Dictionary, action_kind: String, ai_kind: String, delta_ring: float, delta_lane: float, battle_half_height: float) -> bool:
	var reach_by_action: Dictionary = Dictionary(group.get("_reach_by_action", {}))
	var range_limit := float(reach_by_action.get(action_kind, group.get("_ai_reach", 0.0)))
	var lane_limit := 0.38
	if bool(group.get("projectile", false)):
		lane_limit = maxf(lane_limit, battle_half_height * 2.0)
	if ai_kind in ["volley", "mine_dance"]:
		range_limit += 0.42
	if ai_kind == "drone_cloud":
		range_limit += 0.72
		lane_limit += 0.16
	if ai_kind == "screen_wall" and action_kind == "armor":
		lane_limit += 0.24
	return absf(delta_ring) <= range_limit and absf(delta_lane) <= lane_limit


func _group_by_index(groups: Array, attack_index: int) -> Dictionary:
	for raw_group in groups:
		if raw_group is Dictionary:
			var group: Dictionary = raw_group
			if int(group.get("_attack_index", -1)) == attack_index:
				return group
	if attack_index >= 0 and attack_index < groups.size() and groups[attack_index] is Dictionary:
		return Dictionary(groups[attack_index])
	return {"_attack_index": attack_index}


func _is_disabled(disabled_modules: Array, attack_index: int) -> bool:
	return disabled_modules.has(attack_index) or disabled_modules.has(str(attack_index))


func _puppet_cadence(ai_kind: String, unit_index: int) -> float:
	if ai_kind == "volley":
		return 0.18 * float(unit_index)
	if ai_kind == "pincer":
		return 0.08 if unit_index % 2 == 0 else 0.0
	if ai_kind == "mine_dance":
		return 0.32
	return 0.0


func _live_or_fallback(snapshot: Dictionary, fallback: Dictionary) -> Dictionary:
	return snapshot if _snap_live(snapshot) else fallback


func _snap_live(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("live", false))


func _ring_delta(from_value: float, to_value: float, ring_length: float) -> float:
	return fposmod(to_value - from_value + ring_length * 0.5, ring_length) - ring_length * 0.5
