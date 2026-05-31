extends SceneTree

const BattleIdentityRuntimeService := preload("res://scripts/services/battle_identity_runtime_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/battle_identity_runtime_service.gd")
	if source.is_empty():
		_fail("Unable to read BattleIdentityRuntimeService.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "active_units", "all_units", "UnitScene", "GpuCollisionPipeline", "Fighter", "_create_unit", "_assign_unit_role", "queue_free", "randf", "randi", "Time"]:
		if source.contains(forbidden):
			_fail("BattleIdentityRuntimeService contains forbidden token: %s" % forbidden)
			return

	var service := BattleIdentityRuntimeService.new()

	var switch_block := service.role_switch_gate_intent({"unit_live": true, "identity_active": true, "switch_timer": 0.0, "target_role": "puppet"})
	if not _expect(not bool(switch_block.get("accepted", true)) and String(switch_block.get("reason", "")) == "identity_busy", "role switch busy gate mismatch: %s" % str(switch_block)):
		return
	var switch_cooldown := service.role_switch_gate_intent({"unit_live": true, "switch_timer": 1.25, "target_role": "puppet"})
	if not _expect(String(switch_cooldown.get("reason", "")) == "cooldown" and absf(float(switch_cooldown.get("timer", 0.0)) - 1.25) < 0.001, "role switch cooldown gate mismatch: %s" % str(switch_cooldown)):
		return
	var switch_ok := service.role_switch_gate_intent({"unit_live": true, "switch_timer": 0.0, "target_role": "puppet", "plan_found": true})
	if not _expect(bool(switch_ok.get("accepted", false)), "role switch accepted gate mismatch: %s" % str(switch_ok)):
		return

	var soul_not_hero := service.soul_cast_gate_intent({"unit_live": true, "role": "puppet", "switch_timer": 0.0})
	if not _expect(String(soul_not_hero.get("reason", "")) == "not_hero", "soul cast not-hero gate mismatch: %s" % str(soul_not_hero)):
		return
	var soul_no_receiver := service.soul_cast_gate_intent({"unit_live": true, "role": "hero", "switch_timer": 0.0, "target_found": false})
	if not _expect(String(soul_no_receiver.get("reason", "")) == "no_receiver", "soul cast receiver gate mismatch: %s" % str(soul_no_receiver)):
		return

	var candidates := [
		{"role": "puppet", "candidate_index": 0, "distance": 0.42, "order": 0},
		{"role": "barrier", "candidate_index": 1, "distance": 0.24},
		{"role": "puppet", "candidate_index": 2, "distance": 0.12, "order": 1},
	]
	var any_receiver := service.identity_receiver_selection(candidates, "any", 0)
	if not _expect(int(any_receiver.get("candidate_index", -1)) == 2, "identity any receiver should use nearest: %s" % str(any_receiver)):
		return
	var puppet_receiver := service.identity_receiver_selection(candidates, "puppet", 9)
	if not _expect(int(puppet_receiver.get("candidate_index", -1)) == 2, "identity puppet receiver should clamp order: %s" % str(puppet_receiver)):
		return
	var barrier_receiver := service.identity_receiver_selection(candidates, "barrier", 0)
	if not _expect(int(barrier_receiver.get("candidate_index", -1)) == 1, "identity barrier receiver mismatch: %s" % str(barrier_receiver)):
		return
	var switch_target := service.role_switch_target_selection(candidates, "puppet")
	if not _expect(int(switch_target.get("candidate_index", -1)) == 2, "role switch puppet target should use nearest: %s" % str(switch_target)):
		return

	var transfer_plan := service.identity_transfer_plan({"kind": "role_switch", "source_role": "hero", "target_role": "barrier", "target_old_role": "barrier", "role_order": ["hero", "puppet", "barrier"]})
	var plan: Dictionary = transfer_plan.get("plan", {})
	if not _expect(bool(transfer_plan.get("accepted", false)) and String(plan.get("source_new_role", "")) == "barrier" and String(plan.get("target_new_role", "")) == "hero", "role switch transfer plan mismatch: %s" % str(transfer_plan)):
		return
	var soul_plan := service.identity_transfer_plan({"kind": "soul_cast", "source_role": "hero", "target_old_role": "puppet"})
	var soul_payload: Dictionary = soul_plan.get("plan", {})
	if not _expect(String(soul_payload.get("source_new_role", "")) == "puppet" and String(soul_payload.get("target_new_role", "")) == "hero", "soul cast transfer plan mismatch: %s" % str(soul_plan)):
		return

	var form_cycle := service.role_form_target({"role_form_target_role": "cycle_mech_barrier", "role_form_mech_role": "puppet"}, "barrier", ["hero", "puppet", "barrier"])
	if not _expect(form_cycle == "puppet", "role form cycle target mismatch: %s" % form_cycle):
		return
	var form_invalid := service.role_form_target({"role_form_target_role": "dragon"}, "hero", ["hero", "puppet", "barrier"])
	if not _expect(form_invalid == "", "role form invalid target should be empty: %s" % form_invalid):
		return
	var form_occupied := service.role_form_gate_intent({"unit_live": true, "switch_timer": 0.0, "current_role": "puppet", "target_role": "hero", "hero_occupied": true})
	if not _expect(String(form_occupied.get("reason", "")) == "role_occupied", "role form occupancy mismatch: %s" % str(form_occupied)):
		return
	var form_finish := service.role_form_finish_intent({"stats": {"role_form_shape": ""}, "target_role": "puppet", "puppet_shape": "snake", "switch_cooldown": 20.0})
	if not _expect(String(form_finish.get("shape", "")) == "snake" and absf(float(form_finish.get("switch_timer", 0.0)) - 20.0) < 0.001, "role form finish mismatch: %s" % str(form_finish)):
		return

	var morph := service.morph_intent({"unit_live": true, "timer": 0.0, "modes": ["combat", "travel", "siege"], "index": 0, "current_shape": "crab", "cooldown": 2.6})
	if not _expect(bool(morph.get("accepted", false)) and int(morph.get("index", -1)) == 1 and String(morph.get("mode", "")) == "travel" and String(morph.get("shape", "")) == "snake", "morph intent mismatch: %s" % str(morph)):
		return
	var morph_wrap := service.morph_intent({"unit_live": true, "timer": 0.0, "modes": [], "index": 1, "current_shape": "snake"})
	if not _expect(int(morph_wrap.get("index", -1)) == 0 and String(morph_wrap.get("mode", "")) == "combat", "morph fallback/wrap mismatch: %s" % str(morph_wrap)):
		return

	var combine_selection := service.combine_partner_selection([
		{"candidate_index": 0, "distance": 0.5, "delta_x": 0.4, "delta_y": 0.01},
		{"candidate_index": 1, "distance": 0.1, "delta_x": 0.1, "delta_y": 0.01},
		{"candidate_index": 2, "distance": 0.2, "delta_x": 2.0, "delta_y": 0.01},
	], 2, 2, 0.6)
	if not _expect(bool(combine_selection.get("accepted", false)) and Array(combine_selection.get("selected_indices", [])) == [1, 0], "combine selection mismatch: %s" % str(combine_selection)):
		return
	var combine := service.combine_intent({
		"stats": {"shape": "core", "radius": 0.3, "length": 1.0, "combine_shape": "crab", "combine_bonus_hp": 30},
		"max_health": 100,
		"health": 70,
		"partner_snapshots": [
			{"stats": {"radius": 0.2, "length": 0.4}, "health": 20, "max_health": 40, "role": "puppet"},
			{"stats": {"radius": 0.4, "length": 0.6}, "health": 30, "max_health": 50, "role": "puppet"},
		],
	})
	var combined_stats: Dictionary = combine.get("stats", {})
	if not _expect(String(combined_stats.get("shape", "")) == "crab" and absf(float(combined_stats.get("radius", 0.0)) - 0.732) < 0.001 and int(combine.get("max_health", 0)) == 180 and int(combine.get("health", 0)) == 120, "combine intent mismatch: %s" % str(combine)):
		return
	var separate := service.separate_intent({"store": combine.get("combine_store", {}), "health": 999})
	if not _expect(int(separate.get("max_health", 0)) == 100 and int(separate.get("health", 0)) == 100 and Array(separate.get("partner_snapshots", [])).size() == 2, "separate intent mismatch: %s" % str(separate)):
		return
	var spawn := service.separated_partner_spawn_intent({
		"snapshot": {"stats": {"shape": "core"}, "role": "hero", "name": "Returned", "max_health": 44, "health": 21},
		"hero_occupied": true,
		"lead_ring": 9.9,
		"lead_lane": 0.0,
		"ring_length": 10.0,
		"battle_half_height": 1.0,
		"index": 0,
		"count": 2,
	})
	if not _expect(bool(spawn.get("spawn", false)) and String(spawn.get("role", "")) == "puppet" and float(spawn.get("ring", -1.0)) >= 0.0 and float(spawn.get("ring", 11.0)) < 10.0 and int(spawn.get("health", 0)) == 21, "separated partner spawn mismatch: %s" % str(spawn)):
		return

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"scripts/services/battle_identity_runtime_service.gd",
		"BattleIdentityRuntimeService.new",
		"_battle_identity_runtime_service().role_switch_gate_intent",
		"_battle_identity_runtime_service().soul_cast_gate_intent",
		"_battle_identity_runtime_service().identity_receiver_selection",
		"_battle_identity_runtime_service().role_switch_target_selection",
		"_battle_identity_runtime_service().identity_transfer_plan",
		"_battle_identity_runtime_service().role_form_target",
		"_battle_identity_runtime_service().role_form_gate_intent",
		"_battle_identity_runtime_service().role_form_finish_intent",
		"_battle_identity_runtime_service().morph_intent",
		"_battle_identity_runtime_service().morph_shape_for_mode",
		"_battle_identity_runtime_service().combine_partner_selection",
		"_battle_identity_runtime_service().combine_intent",
		"_battle_identity_runtime_service().separate_intent",
		"_battle_identity_runtime_service().separated_partner_spawn_intent",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing BattleIdentityRuntimeService boundary token: %s" % token)
			return

	print("BATTLE_IDENTITY_RUNTIME_SERVICE_CONTRACT_PROBE ok")
	quit(0)
